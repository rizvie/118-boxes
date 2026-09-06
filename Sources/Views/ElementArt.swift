import SwiftUI

/// Deterministic randomness so every element always draws the same sample.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed &* 2_654_435_761 &+ 12_345)
        if state == 0 { state = 0x9E37_79B9 }
    }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

private func polygon(in rect: CGRect, points: Int, jitter: CGFloat,
                     seed: Int, rounded: Bool) -> Path {
    var rng = SeededRNG(seed: seed)
    let centre = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2
    let spin = Double.random(in: 0..<(2 * .pi), using: &rng)

    var verts: [CGPoint] = []
    for i in 0..<points {
        let angle = spin + (Double(i) / Double(points)) * 2 * .pi
        let r = radius * CGFloat.random(in: (1 - jitter)...(1 + jitter * 0.4), using: &rng)
        verts.append(CGPoint(x: centre.x + cos(angle) * r,
                             y: centre.y + sin(angle) * r * 0.88))
    }

    var path = Path()
    if rounded {
        path.move(to: CGPoint(x: (verts[0].x + verts[1].x) / 2,
                              y: (verts[0].y + verts[1].y) / 2))
        for i in 1...verts.count {
            let cur = verts[i % verts.count]
            let next = verts[(i + 1) % verts.count]
            path.addQuadCurve(to: CGPoint(x: (cur.x + next.x) / 2, y: (cur.y + next.y) / 2),
                              control: cur)
        }
    } else {
        path.move(to: verts[0])
        for v in verts.dropFirst() { path.addLine(to: v) }
    }
    path.closeSubpath()
    return path
}

/// A picture of what the element actually looks like, built from its colour,
/// the state it's in and the shape a real sample comes in.
struct ElementArt: View {
    let element: ChemElement
    var animated: Bool = true

    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            ZStack {
                switch element.form {
                case .chunk:   chunk(rect)
                case .ingot:   ingot(rect)
                case .pellets: pellets(rect)
                case .powder:  powder(rect)
                case .crystal: crystal(rect)
                case .wire:    wire(rect)
                case .pool:    pool(rect)
                case .cloud:   cloud(rect)
                case .tube:    tube(rect)
                case .shard:   shard(rect)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            // The specimen box. The samples are drawn to glow off a dark
            // ground, so the box travels with the art rather than depending on
            // whatever screen happens to be showing it. This is what lets the
            // rest of the app be bright.
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.box)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.boxLine, lineWidth: 2)
            )
            // VoiceOver gets what a sighted child gets: what the sample looks
            // like, not which element it is. Naming the element here would hand
            // over the answer in the picture round, and saying nothing at all
            // would make that round unplayable.
            .accessibilityElement()
            .accessibilityLabel(Text(element.artDescription))
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var tint: Color { element.tint }

    /// Metals get a hard sheen, everything else stays matte.
    private func surface(_ shape: Path) -> some View {
        ZStack {
            if element.isShiny {
                shape.fill(LinearGradient(colors: [tint.opacity(0.6), tint, tint.opacity(0.32)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing))
                shape.fill(LinearGradient(colors: [.white.opacity(0.4), .clear],
                                          startPoint: .top, endPoint: .center))
                shape.stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            } else {
                shape.fill(RadialGradient(colors: [tint, tint.opacity(0.52)],
                                          center: .init(x: 0.36, y: 0.3),
                                          startRadius: 1, endRadius: 90))
                shape.stroke(Color.black.opacity(0.28), lineWidth: 2)
            }
        }
        .shadow(color: tint.opacity(element.isShiny ? 0.45 : 0.3), radius: 15)
    }

    // MARK: Chunk

    private func chunk(_ rect: CGRect) -> some View {
        let body = rect.insetBy(dx: rect.width * 0.16, dy: rect.height * 0.2)
        let sides = 5 + (element.z % 5)
        let shape = polygon(in: body, points: sides, jitter: 0.34,
                            seed: element.z, rounded: !element.isShiny)
        return ZStack {
            surface(shape)
            if element.isShiny {
                polygon(in: body.insetBy(dx: body.width * 0.24, dy: body.height * 0.28),
                        points: max(3, sides - 2), jitter: 0.3,
                        seed: element.z + 77, rounded: false)
                    .fill(Color.white.opacity(0.2))
                    .blur(radius: 1)
            } else {
                specks(in: body, count: 12, clip: shape)
            }
        }
    }

    // MARK: Cast bar

    private func ingot(_ rect: CGRect) -> some View {
        let w = rect.width * 0.62
        let h = rect.height * 0.30
        let topInset = w * 0.13
        var top = Path()
        top.move(to: CGPoint(x: -w / 2 + topInset, y: -h / 2 - h * 0.55))
        top.addLine(to: CGPoint(x: w / 2 - topInset, y: -h / 2 - h * 0.55))
        top.addLine(to: CGPoint(x: w / 2, y: -h / 2))
        top.addLine(to: CGPoint(x: -w / 2, y: -h / 2))
        top.closeSubpath()

        return ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(LinearGradient(colors: [tint, tint.opacity(0.45)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: h)
                .offset(y: rect.height * 0.06)
            top
                .fill(LinearGradient(colors: [tint.opacity(0.95), tint.opacity(0.7)],
                                     startPoint: .leading, endPoint: .trailing))
                .offset(x: rect.midX, y: rect.midY + rect.height * 0.06)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                .frame(width: w, height: h)
                .offset(y: rect.height * 0.06)
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: w * 0.4, height: h * 0.16)
                .offset(x: -w * 0.1, y: rect.height * 0.02)
                .blur(radius: 3)
        }
        .shadow(color: tint.opacity(0.5), radius: 16)
    }

    // MARK: Pellets

    private func pellets(_ rect: CGRect) -> some View {
        var rng = SeededRNG(seed: element.z + 401)
        let count = 4 + element.z % 3
        let beads = (0..<count).map { _ -> (CGPoint, CGFloat) in
            (CGPoint(x: CGFloat.random(in: rect.width * 0.28...rect.width * 0.72, using: &rng),
                     y: CGFloat.random(in: rect.height * 0.34...rect.height * 0.7, using: &rng)),
             CGFloat.random(in: rect.width * 0.17...rect.width * 0.27, using: &rng))
        }
        return ZStack {
            ForEach(Array(beads.enumerated()), id: \.offset) { bead in
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [tint, tint.opacity(0.4)],
                                             center: .init(x: 0.35, y: 0.3),
                                             startRadius: 1, endRadius: bead.element.1))
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: bead.element.1 * 0.22, height: bead.element.1 * 0.18)
                        .offset(x: -bead.element.1 * 0.2, y: -bead.element.1 * 0.22)
                        .blur(radius: 1)
                }
                .frame(width: bead.element.1, height: bead.element.1 * 0.86)
                .position(bead.element.0)
            }
        }
        .shadow(color: tint.opacity(0.4), radius: 12)
    }

    // MARK: Powder

    private func powder(_ rect: CGRect) -> some View {
        var rng = SeededRNG(seed: element.z + 733)
        let baseY = rect.height * 0.70
        let left = rect.width * 0.18
        let right = rect.width * 0.82
        let peak = baseY - rect.height * CGFloat.random(in: 0.30...0.42, using: &rng)
        let lean = CGFloat.random(in: -0.12...0.12, using: &rng)
        let apexX = rect.midX + rect.width * lean

        // One smooth heap, the way powder actually settles.
        var mound = Path()
        mound.move(to: CGPoint(x: left, y: baseY))
        mound.addCurve(to: CGPoint(x: apexX, y: peak),
                       control1: CGPoint(x: left + (apexX - left) * 0.35, y: baseY),
                       control2: CGPoint(x: apexX - (apexX - left) * 0.45, y: peak))
        mound.addCurve(to: CGPoint(x: right, y: baseY),
                       control1: CGPoint(x: apexX + (right - apexX) * 0.45, y: peak),
                       control2: CGPoint(x: right - (right - apexX) * 0.35, y: baseY))
        mound.closeSubpath()

        return ZStack {
            mound.fill(LinearGradient(colors: [tint, tint.opacity(0.5)],
                                      startPoint: .top, endPoint: .bottom))
            // A lighter face on the lit side of the heap.
            mound.fill(LinearGradient(colors: [.white.opacity(0.18), .clear],
                                      startPoint: .topLeading, endPoint: .bottom))
            specks(in: CGRect(x: left, y: peak, width: right - left, height: baseY - peak),
                   count: 26, clip: mound)
            Ellipse()
                .fill(tint.opacity(0.45))
                .frame(width: (right - left) * 1.02, height: rect.height * 0.07)
                .position(x: rect.midX, y: baseY)
                .blur(radius: 3)
        }
        .shadow(color: tint.opacity(0.35), radius: 12)
    }

    // MARK: Crystal cluster

    private func crystal(_ rect: CGRect) -> some View {
        var rng = SeededRNG(seed: element.z + 197)
        let spikes = (0..<3).map { i -> (CGFloat, CGFloat, CGFloat) in
            (CGFloat.random(in: -0.2...0.2, using: &rng),      // x offset
             CGFloat.random(in: 0.5...0.92, using: &rng),      // height factor
             CGFloat(i - 1) * 22 + CGFloat.random(in: -8...8, using: &rng)) // tilt
        }
        return ZStack {
            ForEach(Array(spikes.enumerated()), id: \.offset) { item in
                let s = item.element
                let w = rect.width * 0.24
                let h = rect.height * s.1
                ZStack {
                    prismPath(width: w, height: h)
                        .fill(LinearGradient(colors: [tint.opacity(0.95), tint.opacity(0.4)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    prismPath(width: w, height: h)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1.2)
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: w * 0.22, height: h * 0.75)
                        .offset(x: -w * 0.16)
                        .blur(radius: 2)
                }
                .frame(width: w, height: h)
                .rotationEffect(.degrees(Double(s.2)))
                .position(x: rect.midX + rect.width * s.0,
                          y: rect.midY + rect.height * (0.5 - s.1 / 2) * 0.7)
            }
        }
        .shadow(color: tint.opacity(0.55), radius: 16)
    }

    private func prismPath(width w: CGFloat, height h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: w / 2, y: 0))
        p.addLine(to: CGPoint(x: w, y: h * 0.28))
        p.addLine(to: CGPoint(x: w * 0.82, y: h))
        p.addLine(to: CGPoint(x: w * 0.18, y: h))
        p.addLine(to: CGPoint(x: 0, y: h * 0.28))
        p.closeSubpath()
        return p
    }

    // MARK: Coil of wire

    private func wire(_ rect: CGRect) -> some View {
        let turns = 5
        let coilW = rect.width * 0.46
        let coilH = rect.height * 0.13
        let step = rect.height * 0.10
        let top = rect.midY - step * CGFloat(turns - 1) / 2

        // A spring: each turn is an arc, stepped down the screen.
        return ZStack {
            ForEach(0..<turns, id: \.self) { i in
                Path { p in
                    let y = top + step * CGFloat(i)
                    p.addArc(center: CGPoint(x: rect.midX, y: y),
                             radius: coilW / 2,
                             startAngle: .degrees(160), endAngle: .degrees(20),
                             clockwise: true)
                }
                .transform(CGAffineTransform(translationX: 0, y: 0))
                .scale(x: 1, y: coilH / (coilW / 2) * 2, anchor: .center)
                .stroke(LinearGradient(colors: [tint.opacity(0.5), tint, tint.opacity(0.5)],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: max(3.5, rect.width * 0.05),
                                           lineCap: .round))
            }
            // Loose end of the wire coming off the bottom turn.
            Path { p in
                p.move(to: CGPoint(x: rect.midX + coilW / 2,
                                   y: top + step * CGFloat(turns - 1)))
                p.addQuadCurve(to: CGPoint(x: rect.midX + coilW * 0.72,
                                           y: rect.maxY - rect.height * 0.18),
                               control: CGPoint(x: rect.midX + coilW * 0.78,
                                                y: rect.maxY - rect.height * 0.3))
            }
            .stroke(tint, style: StrokeStyle(lineWidth: max(3.5, rect.width * 0.05),
                                             lineCap: .round))
        }
        .shadow(color: tint.opacity(0.5), radius: 13)
    }

    // MARK: Liquid

    private func pool(_ rect: CGRect) -> some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [tint, tint.opacity(0.55)],
                                     center: .init(x: 0.4, y: 0.35),
                                     startRadius: 2, endRadius: rect.width * 0.5))
                .frame(width: rect.width * 0.66, height: rect.height * 0.24)
                .offset(y: rect.height * 0.22)
            Circle()
                .fill(RadialGradient(colors: [tint, tint.opacity(0.5)],
                                     center: .init(x: 0.35, y: 0.3),
                                     startRadius: 1, endRadius: rect.width * 0.3))
                .frame(width: rect.width * 0.38, height: rect.width * 0.38)
                .offset(x: -rect.width * 0.1, y: -rect.height * 0.08)
            Circle()
                .fill(tint.opacity(0.9))
                .frame(width: rect.width * 0.17, height: rect.width * 0.17)
                .offset(x: rect.width * 0.2, y: 0)
            Ellipse()
                .fill(Color.white.opacity(0.75))
                .frame(width: rect.width * 0.1, height: rect.height * 0.045)
                .offset(x: -rect.width * 0.16, y: -rect.height * 0.17)
                .blur(radius: 2)
        }
        .shadow(color: tint.opacity(0.5), radius: 18)
    }

    // MARK: Gas

    private func cloud(_ rect: CGRect) -> some View {
        var rng = SeededRNG(seed: element.z + 313)
        let puffs = (0..<5).map { _ -> (CGPoint, CGFloat) in
            (CGPoint(x: CGFloat.random(in: rect.width * 0.3...rect.width * 0.7, using: &rng),
                     y: CGFloat.random(in: rect.height * 0.32...rect.height * 0.68, using: &rng)),
             CGFloat.random(in: rect.width * 0.3...rect.width * 0.52, using: &rng))
        }
        var rng2 = SeededRNG(seed: element.z + 555)
        let motes = (0..<10).map { _ in
            CGPoint(x: CGFloat.random(in: rect.width * 0.2...rect.width * 0.8, using: &rng2),
                    y: CGFloat.random(in: rect.height * 0.2...rect.height * 0.8, using: &rng2))
        }
        return ZStack {
            ForEach(Array(puffs.enumerated()), id: \.offset) { item in
                Circle()
                    .fill(RadialGradient(colors: [tint.opacity(0.6), .clear],
                                         center: .center, startRadius: 0,
                                         endRadius: item.element.1 / 2))
                    .frame(width: item.element.1, height: item.element.1)
                    .position(item.element.0)
            }
            .blur(radius: 6)
            ForEach(Array(motes.enumerated()), id: \.offset) { mote in
                Circle()
                    .fill(tint)
                    .frame(width: 5, height: 5)
                    .position(mote.element)
                    .opacity(pulse ? 0.9 : 0.3)
                    .offset(y: pulse ? -6 : 6)
                    .animation(.easeInOut(duration: 2 + Double(mote.offset % 4) * 0.4)
                        .repeatForever(autoreverses: true), value: pulse)
            }
        }
        .scaleEffect(pulse ? 1.04 : 0.97)
    }

    // MARK: Noble gas tube

    private func tube(_ rect: CGRect) -> some View {
        let h = min(rect.height * 0.78, rect.width * 1.3)
        let w = min(rect.width * 0.42, h * 0.42)
        return ZStack {
            RoundedRectangle(cornerRadius: w / 2, style: .continuous)
                .fill(tint.opacity(0.2))
                .frame(width: w, height: h)
            RoundedRectangle(cornerRadius: w / 2, style: .continuous)
                .stroke(tint, lineWidth: 6)
                .frame(width: w, height: h)
                .blur(radius: 9)
                .opacity(pulse ? 1 : 0.6)
            RoundedRectangle(cornerRadius: w / 2, style: .continuous)
                .stroke(tint, lineWidth: 3)
                .frame(width: w, height: h)
            RoundedRectangle(cornerRadius: w / 2, style: .continuous)
                .stroke(Color.white.opacity(0.75), lineWidth: 1)
                .frame(width: w, height: h)
        }
        .shadow(color: tint.opacity(0.8), radius: pulse ? 24 : 13)
    }

    // MARK: Radioactive shard

    private func shard(_ rect: CGRect) -> some View {
        let body = rect.insetBy(dx: rect.width * 0.24, dy: rect.height * 0.2)
        let shape = polygon(in: body, points: 5 + element.z % 3, jitter: 0.38,
                            seed: element.z, rounded: false)
        return ZStack {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(pulse ? 0.4 : 0.15), .clear],
                                     center: .center, startRadius: 0, endRadius: rect.width * 0.5))
                .frame(width: rect.width, height: rect.width)
            shape.fill(LinearGradient(colors: [tint, tint.opacity(0.42)],
                                      startPoint: .top, endPoint: .bottom))
            shape.stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            Circle()
                .stroke(tint.opacity(pulse ? 0.5 : 0.12), lineWidth: 2)
                .frame(width: rect.width * (pulse ? 0.9 : 0.55),
                       height: rect.width * (pulse ? 0.9 : 0.55))
        }
        .shadow(color: tint.opacity(0.7), radius: pulse ? 22 : 11)
    }

    // MARK: Shared bits

    private func specks(in rect: CGRect, count: Int, clip: Path) -> some View {
        var rng = SeededRNG(seed: element.z + 991)
        let points = (0..<count).map { _ in
            CGPoint(x: CGFloat.random(in: rect.minX...rect.maxX, using: &rng),
                    y: CGFloat.random(in: rect.minY...rect.maxY, using: &rng))
        }
        return ForEach(Array(points.enumerated()), id: \.offset) { p in
            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: 4, height: 4)
                .position(p.element)
        }
        .clipShape(clip)
    }
}

/// Art plus the little caption saying what state it's in.
struct SampleView: View {
    let element: ChemElement
    var showCaption = true

    var body: some View {
        VStack(spacing: 6) {
            ElementArt(element: element)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if showCaption {
                Text(element.phase.label.uppercased())
                    .font(Theme.rounded(11, .heavy))
                    .tracking(1.4)
                    .foregroundStyle(Theme.textLo)
            }
        }
    }
}
