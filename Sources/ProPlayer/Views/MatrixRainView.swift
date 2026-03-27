import SwiftUI

struct MatrixRainView: View {
    let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*")
    @State private var columns: [MatrixColumn] = []
    let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()
    
    struct MatrixColumn {
        var x: CGFloat
        var y: CGFloat
        var speed: CGFloat
        var chars: [String]
        var length: Int
    }
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for col in columns {
                    for (index, char) in col.chars.enumerated() {
                        let yPos = col.y - CGFloat(index * 20)
                        if yPos > 0 && yPos < size.height {
                            let opacity = 1.0 - (Double(index) / Double(col.length))
                            let color = index == 0 ? Color.white : Color(red: 0.1, green: 0.9, blue: 1.0)
                            
                            context.opacity = opacity
                            context.draw(
                                Text(char)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(color),
                                at: CGPoint(x: col.x, y: yPos),
                                anchor: .top
                            )
                        }
                    }
                }
            }
            .onReceive(timer) { _ in
                updateColumns(in: geometry.size)
            }
            .onAppear {
                setupColumns(in: geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                setupColumns(in: newSize)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private func setupColumns(in size: CGSize) {
        let numColumns = Int(size.width / 20) + 1
        columns = (0..<numColumns).map { i in
            createInitialColumn(xIndex: i, maxHeight: size.height)
        }
    }
    
    private func createInitialColumn(xIndex: Int, maxHeight: CGFloat) -> MatrixColumn {
        let length = Int.random(in: 10...30)
        let randomChars = (0..<length).map { _ in String(characters.randomElement() ?? "A") }
        
        return MatrixColumn(
            x: CGFloat(xIndex * 20),
            y: CGFloat.random(in: -maxHeight...maxHeight),
            speed: CGFloat.random(in: 5...15),
            chars: randomChars,
            length: length
        )
    }
    
    private func updateColumns(in size: CGSize) {
        for i in columns.indices {
            // Update y position
            columns[i].y += columns[i].speed
            
            // Randomly change some characters (Matrix effect)
            if Int.random(in: 0...10) > 8 {
                let randomIdx = Int.random(in: 0..<columns[i].chars.count)
                columns[i].chars[randomIdx] = String(characters.randomElement() ?? "A")
            }
            
            // Reset column if it goes entirely off screen
            if columns[i].y - CGFloat(columns[i].length * 20) > size.height {
                columns[i] = createInitialColumn(xIndex: Int(columns[i].x / 20), maxHeight: size.height)
                columns[i].y = CGFloat.random(in: -200...0)
            }
        }
    }
}
