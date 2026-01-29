//
//  MedicalReportGenerator.swift
//  NEW5
//
//  Generates PDF medical reports from health log data. Stores in Application Support.
//

import Foundation
import UIKit
import SwiftData

struct MedicalReportGenerator {

    /// Generate PDF report for date range and save to Application Support. Returns file URL.
    static func generate(
        from start: Date,
        to end: Date,
        modelContext: ModelContext
    ) throws -> URL {
        let controller = HealthLogController(modelContext: modelContext)
        let entries = try controller.entries(from: start, to: end)
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateOnly = DateFormatter()
        dateOnly.dateStyle = .medium
        dateOnly.timeStyle = .none

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let name = "SugarScope_Report_\(df.string(from: start))_\(df.string(from: end)).pdf"
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appending(path: "MedicalReports", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appending(path: name)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 40
            let left: CGFloat = 50
            let w: CGFloat = 512

            func draw(_ s: String, font: UIFont = .systemFont(ofSize: 12), color: UIColor = .black) {
                let att: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let rect = CGRect(x: left, y: y, width: w, height: 60)
                (s as NSString).draw(in: rect, withAttributes: att)
                y += 22
            }

            draw("SugarScope — Medical Report", font: .boldSystemFont(ofSize: 18), color: UIColor(red: 0.2, green: 0.55, blue: 0.35, alpha: 1))
            draw("Generated \(formatter.string(from: Date()))")
            draw("Period: \(formatter.string(from: start)) – \(formatter.string(from: end))")
            y += 10

            var byDay: [Date: [HealthLogEntry]] = [:]
            for e in entries {
                let d = cal.startOfDay(for: e.timestamp)
                byDay[d, default: []].append(e)
            }
            let days = byDay.keys.sorted()

            for d in days {
                let dayEntries = byDay[d]!.sorted { $0.timestamp < $1.timestamp }
                draw("\(dateOnly.string(from: d))", font: .boldSystemFont(ofSize: 14))
                for e in dayEntries {
                    var line = "\(formatter.string(from: e.timestamp)) — \(e.kind)"
                    if let v = e.value { line += " \(v)" }
                    if let u = e.unit { line += " \(u)" }
                    if let n = e.note { line += " — \(n)" }
                    if let m = e.mealDescription { line += " | \(m)" }
                    draw(line)
                }
                y += 6
            }

            draw("")
            draw("This report is for personal use. Share with your care team as needed. Data stored securely on device.", font: .systemFont(ofSize: 10))
        }

        try data.write(to: url)
        return url
    }
}
