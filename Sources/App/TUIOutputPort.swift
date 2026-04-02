// TUIOutputPort — adapter boundary between Renderer and terminal I/O.

protocol TUIOutputPort: AnyObject {
    func write(_ string: String)
    func moveCursor(row: Int, col: Int)
    func clearScreen()
    func hideCursor()
    func showCursor()
    func flush()
}
