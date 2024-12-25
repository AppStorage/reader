import SwiftUI

extension ContentViewModel {
    // Toggles the selection state of a tag
    func toggleTagSelection(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    // Clears a specific tag from the selectedTags set
    func clearTag(_ tag: String) {
        selectedTags.remove(tag)
    }
}
