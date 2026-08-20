import SwiftUI
import AppKit

@MainActor
public struct ProjectCenterButtonView: View {
    public let project: Project?
    public let folderCount: Int
    public var onOptionClick: () -> Void
    public var onNormalClick: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var isOptionKeyPressed: Bool = false
    @State private var eventMonitor: Any?
    
    public init(
        project: Project?,
        folderCount: Int,
        onOptionClick: @escaping () -> Void,
        onNormalClick: @escaping () -> Void
    ) {
        self.project = project
        self.folderCount = folderCount
        self.onOptionClick = onOptionClick
        self.onNormalClick = onNormalClick
    }
    
    public var body: some View {
        Button(action: handleClick) {
            ZStack {
                // Circular Background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                (project?.accentColor ?? Color.accentColor).opacity(isHovered ? 0.35 : 0.22),
                                Color(nsColor: .windowBackgroundColor).opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isOptionKeyPressed || isHovered
                                    ? (project?.accentColor ?? Color.accentColor).opacity(0.8)
                                    : Color.white.opacity(0.2),
                                lineWidth: isOptionKeyPressed ? 2.5 : (isHovered ? 2.0 : 1.2)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                
                // Content
                VStack(spacing: 4) {
                    if isOptionKeyPressed {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(project?.accentColor ?? .accentColor)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Circle()
                            .fill(project?.accentColor ?? .accentColor)
                            .frame(width: 8, height: 8)
                    }
                    
                    // Project Title
                    Text((project?.name ?? "PROJECT").uppercased())
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 14)
                    
                    // Subtitle / Hint
                    Text(isOptionKeyPressed ? "PROJECT MENU" : (isHovered ? "⌥ CLICK FOR MENU" : "\(folderCount) FOLDERS"))
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(isOptionKeyPressed ? (project?.accentColor ?? .accentColor) : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.primary.opacity(0.06))
                        )
                }
                .padding(8)
            }
            .frame(width: 140, height: 140)
            .contentShape(Circle())
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: isHovered)
            .animation(.easeInOut(duration: 0.15), value: isOptionKeyPressed)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onHover { hovering in
            isHovered = hovering
            checkModifierFlags()
        }
        .onAppear {
            startFlagsMonitoring()
        }
        .onDisappear {
            stopFlagsMonitoring()
        }
    }
    
    private func handleClick() {
        let flags = NSEvent.modifierFlags
        if flags.contains(.option) {
            onOptionClick()
        } else {
            onNormalClick()
        }
    }
    
    private func checkModifierFlags() {
        isOptionKeyPressed = NSEvent.modifierFlags.contains(.option)
    }
    
    private func startFlagsMonitoring() {
        stopFlagsMonitoring()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { event in
            DispatchQueue.main.async {
                self.isOptionKeyPressed = event.modifierFlags.contains(.option)
            }
            return event
        }
    }
    
    private func stopFlagsMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
