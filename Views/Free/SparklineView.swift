import SwiftUI

// MARK: - SparklineView (fill + line version, replaces old line-only)
struct SparklineView: View {
    var data: [Double]
    var color: Color
    var height: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                let minV  = data.min() ?? 0
                let maxV  = data.max() ?? 1
                let range = maxV - minV == 0 ? 1.0 : maxV - minV
                let w     = geo.size.width / CGFloat(data.count - 1)

                ZStack {
                    // Fill under curve
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geo.size.height))
                        for (i, val) in data.enumerated() {
                            let x = CGFloat(i) * w
                            let y = geo.size.height * (1 - CGFloat((val - minV) / range))
                            if i == 0 { path.addLine(to: CGPoint(x: x, y: y)) }
                            else       { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(
                        colors: [color.opacity(0.25), color.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    ))

                    // Stroke line
                    Path { path in
                        for (i, val) in data.enumerated() {
                            let x = CGFloat(i) * w
                            let y = geo.size.height * (1 - CGFloat((val - minV) / range))
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else       { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .frame(height: height)
        .animation(.linear(duration: 0.3), value: data.count)
    }
}
