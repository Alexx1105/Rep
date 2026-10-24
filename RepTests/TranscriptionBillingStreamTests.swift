import XCTest
import Foundation
@testable import Rep

final class TranscriptionBillingStreamTests: XCTestCase {
    private let billing = #"{"rep_billing":{"bucket":{"id":"78729f1f-2e04-4194-8916-78774c703b19","user_id":"11111111-1111-4111-8111-111111111111","consumed":23.8068,"reserved":0,"allowance":30,"feature_id":"cc406cc5-38d8-49ed-a75e-a188bcd7d15f","period_end":null,"bucket_type":"lifetime","period_start":null},"reservation":{"status":"completed","charged_units":1}}}"#

    func testBillingEnvelopeWithoutTypeDecodesAsBilling() throws {
        let data = Data(billing.utf8)
        // Reproduces the old failure with this exact event shape.
        XCTAssertThrowsError(try JSONDecoder().decode(StreamEvent.self, from: data))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(BillingSseResponse.self, from: data)
        XCTAssertEqual(envelope.rep_billing.bucket.consumed, Decimal(string: "23.8068"))
        XCTAssertEqual(envelope.rep_billing.bucket.allowance, 30)
    }

    func testMixedStreamPreservesSummaryAndProcessesBillingAfterCompletion() throws {
        let events = [
            #"{"type":"response.output_text.delta","delta":"Synthetic summary"}"#,
            #"{"type":"response.completed","response":{"id":"resp_diagnostic","status":"completed","model":"diagnostic"}}"#,
            billing
        ]
        var notes = ""
        var completed = false
        var billingCount = 0
        for payload in events {
            let data = Data(payload.utf8)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let envelope = try? decoder.decode(BillingSseResponse.self, from: data) {
                XCTAssertTrue(completed, "Billing follows the completed response")
                XCTAssertEqual(envelope.rep_billing.bucket.consumed, Decimal(string: "23.8068"))
                billingCount += 1
                continue
            }
            let event = try JSONDecoder().decode(StreamEvent.self, from: data)
            if let delta = event.delta { notes += delta }
            if event.type == "response.completed" { completed = true }
        }
        XCTAssertEqual(notes, "Synthetic summary")
        XCTAssertTrue(completed)
        XCTAssertEqual(billingCount, 1)
    }

    func testMalformedNonBillingEventStillFails() {
        let data = Data(#"{"unexpected":"event"}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(BillingSseResponse.self, from: data))
        XCTAssertThrowsError(try JSONDecoder().decode(StreamEvent.self, from: data))
    }
}
