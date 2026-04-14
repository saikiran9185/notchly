import SwiftUI

struct AsymmetricRoundedRect: Shape {
    let topRadius: CGFloat
    let bottomRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let top = min(topRadius, min(rect.width, rect.height) / 2)
        let bottom = min(bottomRadius, min(rect.width, rect.height) / 2)

        path.move(to: CGPoint(x: top, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - top, y: rect.minY))

        if top > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + top),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottom))

        if bottom > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - bottom, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        }

        path.addLine(to: CGPoint(x: rect.minX + bottom, y: rect.maxY))

        if bottom > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - bottom),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
        }

        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + top))

        if top > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + top, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }

        path.closeSubpath()
        return path
    }
}
