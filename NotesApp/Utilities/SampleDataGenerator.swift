import Foundation
import SwiftData

/// Sample data generator for testing and preview purposes
struct SampleDataGenerator {
    
    /// Create sample data in the provided model context
    static func createSampleData(in context: ModelContext) {
        // Create sample folders
        let workFolder = createWorkFolder(in: context)
        let personalFolder = createPersonalFolder(in: context)
        let projectsFolder = createProjectsFolder(in: context)
        
        // Create sample tags
        let importantTag = createImportantTag(in: context)
        let urgentTag = createUrgentTag(in: context)
        let ideaTag = createIdeaTag(in: context)
        let meetingTag = createMeetingTag(in: context)
        
        // Create sample notes
        createSampleNotes(
            in: context,
            folders: [workFolder, personalFolder, projectsFolder],
            tags: [importantTag, urgentTag, ideaTag, meetingTag]
        )
        
        // Save the context
        do {
            try context.save()
        } catch {
            print("Failed to save sample data: \(error)")
        }
    }
    
    // MARK: - Folder Creation
    
    private static func createWorkFolder(in context: ModelContext) -> Folder {
        let folder = Folder(
            name: "Work",
            color: FolderColor.blue.rawValue,
            icon: FolderIcon.work.rawValue
        )
        context.insert(folder)
        return folder
    }
    
    private static func createPersonalFolder(in context: ModelContext) -> Folder {
        let folder = Folder(
            name: "Personal",
            color: FolderColor.green.rawValue,
            icon: FolderIcon.personal.rawValue
        )
        context.insert(folder)
        return folder
    }
    
    private static func createProjectsFolder(in context: ModelContext) -> Folder {
        let folder = Folder(
            name: "Projects",
            color: FolderColor.purple.rawValue,
            icon: FolderIcon.projects.rawValue
        )
        context.insert(folder)
        return folder
    }
    
    // MARK: - Tag Creation
    
    private static func createImportantTag(in context: ModelContext) -> Tag {
        let tag = Tag(name: "important", color: TagColor.red.rawValue)
        context.insert(tag)
        return tag
    }
    
    private static func createUrgentTag(in context: ModelContext) -> Tag {
        let tag = Tag(name: "urgent", color: TagColor.orange.rawValue)
        context.insert(tag)
        return tag
    }
    
    private static func createIdeaTag(in context: ModelContext) -> Tag {
        let tag = Tag(name: "idea", color: TagColor.yellow.rawValue)
        context.insert(tag)
        return tag
    }
    
    private static func createMeetingTag(in context: ModelContext) -> Tag {
        let tag = Tag(name: "meeting", color: TagColor.blue.rawValue)
        context.insert(tag)
        return tag
    }
    
    // MARK: - Note Creation
    
    private static func createSampleNotes(
        in context: ModelContext,
        folders: [Folder],
        tags: [Tag]
    ) {
        let sampleNotes = [
            SampleNoteData(
                title: "Project Kickoff Meeting",
                content: """
                # Project Kickoff Meeting
                
                **Date:** \(Date().formatted(date: .abbreviated, time: .shortened))
                **Attendees:** John, Sarah, Mike, Lisa
                
                ## Agenda
                - Project overview and objectives
                - Timeline and milestones
                - Resource allocation
                - Risk assessment
                
                ## Key Decisions
                - Launch date set for Q2 2024
                - Weekly standup meetings on Mondays
                - Use Agile methodology
                
                ## Action Items
                - [ ] Create project charter (John)
                - [ ] Set up development environment (Mike)
                - [ ] Design initial mockups (Sarah)
                - [ ] Schedule stakeholder review (Lisa)
                
                ## Next Steps
                - Follow up meeting scheduled for next week
                - Begin sprint planning
                """,
                folder: folders[0], // Work folder
                tags: [tags[0], tags[3]], // Important, Meeting
                isFavorite: true,
                templateType: .meeting
            ),
            
            SampleNoteData(
                title: "App Ideas Brainstorm",
                content: """
                # App Ideas Brainstorm Session
                
                ## Productivity Apps
                - Task manager with AI suggestions
                - Time tracking with smart categorization
                - Note-taking app with handwriting recognition ✨
                - Calendar app with natural language input
                
                ## Creative Apps
                - Digital art studio for iPad
                - Music composition tool
                - Story writing assistant
                - Photo editing with AI filters
                
                ## Utility Apps
                - Password manager with biometric sync
                - File organizer with smart tagging
                - Network analyzer for developers
                - System monitor dashboard
                
                ## Best Ideas (Top 3)
                1. **Note-taking app with handwriting recognition** - High demand, good monetization potential
                2. **Task manager with AI suggestions** - Unique selling point, growing market
                3. **Digital art studio for iPad** - Creative market, Apple Pencil integration
                
                ## Next Steps
                - Research competition for top 3 ideas
                - Create user personas
                - Develop MVP specifications
                """,
                folder: folders[2], // Projects folder
                tags: [tags[2]], // Idea
                isFavorite: false,
                templateType: .brainstorm
            ),
            
            SampleNoteData(
                title: "Daily Journal - Today's Reflections",
                content: """
                # Daily Journal - \(Date().formatted(date: .complete, time: .omitted))
                
                ## Today's Highlights
                - Completed the SwiftUI tutorial on navigation
                - Had a great coffee chat with Sarah about the new project
                - Finished reading chapter 3 of "Atomic Habits"
                - Went for a 30-minute walk in the park
                
                ## Thoughts & Reflections
                Today was productive and fulfilling. I'm getting more comfortable with SwiftUI's navigation system, and the concepts are starting to click. The conversation with Sarah gave me some great insights into project management.
                
                I'm particularly excited about implementing the ideas from "Atomic Habits" into my daily routine. The concept of habit stacking seems very practical.
                
                ## Challenges
                - Still struggling with some advanced SwiftUI concepts
                - Need to better manage my time between learning and actual development
                - Should spend less time on social media
                
                ## Gratitude
                - Grateful for supportive colleagues like Sarah
                - Thankful for the beautiful weather today
                - Appreciate having access to great learning resources
                
                ## Tomorrow's Goals
                - Continue with SwiftUI data flow tutorial
                - Start implementing the note-taking app prototype
                - Call mom to catch up
                - Go to the gym after work
                """,
                folder: folders[1], // Personal folder
                tags: [],
                isFavorite: false,
                templateType: .journal
            ),
            
            SampleNoteData(
                title: "SwiftUI Learning Notes",
                content: """
                # SwiftUI Learning Notes
                
                ## Key Concepts
                
                ### State Management
                - `@State` for local state
                - `@Binding` for two-way data binding
                - `@ObservedObject` for external objects
                - `@StateObject` for object ownership
                - `@EnvironmentObject` for shared data
                
                ### Navigation
                - `NavigationView` for basic navigation
                - `NavigationSplitView` for iPad layouts
                - `NavigationLink` for navigation triggers
                - Programmatic navigation with `NavigationPath`
                
                ### Layout System
                - `VStack`, `HStack`, `ZStack` for basic layouts
                - `LazyVStack`, `LazyHStack` for performance
                - `Grid` and `LazyVGrid` for complex layouts
                - Alignment and spacing modifiers
                
                ## Best Practices
                1. Keep views small and focused
                2. Extract reusable components
                3. Use proper state management
                4. Optimize for performance with lazy loading
                5. Follow Apple's Human Interface Guidelines
                
                ## Common Pitfalls
                - Overusing `@State` instead of proper architecture
                - Not considering iPad layouts
                - Ignoring accessibility
                - Poor performance with large lists
                
                ## Resources
                - Apple's SwiftUI documentation
                - WWDC sessions on SwiftUI
                - Hacking with Swift tutorials
                - SwiftUI by Example
                """,
                folder: folders[0], // Work folder
                tags: [tags[0]], // Important
                isFavorite: true,
                templateType: nil
            ),
            
            SampleNoteData(
                title: "Weekend To-Do List",
                content: """
                # Weekend To-Do List
                
                ## Saturday
                - [ ] Grocery shopping
                - [ ] Clean the apartment
                - [ ] Work on SwiftUI project
                - [ ] Call parents
                - [ ] Go for a run
                - [ ] Meal prep for next week
                
                ## Sunday
                - [ ] Finish reading current book
                - [ ] Plan next week's schedule
                - [ ] Do laundry
                - [ ] Work in the garden
                - [ ] Prepare for Monday's meeting
                - [ ] Relax and unwind
                
                ## This Week's Goals
                - [ ] Complete the note-taking app prototype
                - [ ] Submit project proposal
                - [ ] Schedule dentist appointment
                - [ ] Update resume
                - [ ] Research vacation destinations
                
                ## Someday/Maybe
                - [ ] Learn a new programming language
                - [ ] Start a side project
                - [ ] Take a photography course
                - [ ] Organize digital photos
                - [ ] Write a blog post about SwiftUI
                """,
                folder: folders[1], // Personal folder
                tags: [tags[1]], // Urgent
                isFavorite: false,
                templateType: .todoList
            ),
            
            SampleNoteData(
                title: "Recipe: Homemade Pizza",
                content: """
                # Homemade Pizza Recipe
                
                **Prep Time:** 30 minutes
                **Cook Time:** 15 minutes
                **Total Time:** 45 minutes
                **Servings:** 4
                
                ## Ingredients
                
                ### For the Dough
                - 2 cups all-purpose flour
                - 1 packet (2¼ tsp) active dry yeast
                - 1 tsp sugar
                - 1 tsp salt
                - ¾ cup warm water
                - 2 tbsp olive oil
                
                ### For the Toppings
                - ½ cup pizza sauce
                - 2 cups shredded mozzarella cheese
                - ¼ cup grated Parmesan cheese
                - Pepperoni slices (optional)
                - Fresh basil leaves
                - Italian seasoning
                
                ## Instructions
                
                1. **Prepare the dough:** In a large bowl, combine warm water, sugar, and yeast. Let sit for 5 minutes until foamy.
                
                2. **Mix ingredients:** Add flour, salt, and olive oil to the yeast mixture. Mix until a dough forms.
                
                3. **Knead the dough:** Turn onto a floured surface and knead for 5-7 minutes until smooth and elastic.
                
                4. **Let rise:** Place in an oiled bowl, cover, and let rise for 1 hour or until doubled in size.
                
                5. **Preheat oven:** Heat oven to 475°F (245°C).
                
                6. **Shape the pizza:** Roll out dough on a floured surface to fit your pizza pan.
                
                7. **Add toppings:** Spread sauce evenly, add cheeses and desired toppings.
                
                8. **Bake:** Cook for 12-15 minutes until crust is golden and cheese is bubbly.
                
                9. **Serve:** Let cool for 2-3 minutes, then slice and serve hot.
                
                ## Notes
                - For a crispier crust, pre-bake the dough for 5 minutes before adding toppings
                - Experiment with different cheese combinations
                - Fresh herbs make a big difference in flavor
                - Leftover dough can be frozen for up to 3 months
                """,
                folder: folders[1], // Personal folder
                tags: [],
                isFavorite: true,
                templateType: .recipe
            )
        ]
        
        // Create notes from sample data
        for sampleNote in sampleNotes {
            let note = Note(
                title: sampleNote.title,
                content: sampleNote.content,
                folder: sampleNote.folder,
                templateType: sampleNote.templateType
            )
            
            note.isFavorite = sampleNote.isFavorite
            
            // Add some variation to creation dates
            let daysAgo = Int.random(in: 0...30)
            note.createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            note.modifiedAt = Calendar.current.date(byAdding: .hour, value: -Int.random(in: 0...24), to: note.createdAt) ?? note.createdAt
            
            context.insert(note)
            
            // Add to folder
            sampleNote.folder.notes.append(note)
            
            // Add tags
            for tag in sampleNote.tags {
                note.tags.append(tag)
                tag.notes.append(note)
                tag.incrementUsage()
            }
        }
    }
}

/// Sample note data structure
private struct SampleNoteData {
    let title: String
    let content: String
    let folder: Folder
    let tags: [Tag]
    let isFavorite: Bool
    let templateType: NoteTemplate?
}

/// Extension for creating additional sample content
extension SampleDataGenerator {
    
    /// Create sample attachments for testing
    static func createSampleAttachments(for note: Note, in context: ModelContext) {
        let attachments = [
            Attachment(fileName: "meeting-notes.pdf", fileType: .pdf, fileSize: 1024000),
            Attachment(fileName: "project-diagram.png", fileType: .image, fileSize: 512000),
            Attachment(fileName: "voice-memo.m4a", fileType: .audio, fileSize: 2048000)
        ]
        
        for attachment in attachments {
            attachment.note = note
            note.attachments.append(attachment)
            context.insert(attachment)
        }
    }
    
    /// Create sample handwriting data
    static func addSampleHandwriting(to note: Note) {
        // In a real implementation, this would create actual PKDrawing data
        // For now, we'll just mark the note as having handwriting
        note.hasHandwriting = true
        note.handwritingData = Data() // Placeholder data
    }
    
    /// Create additional sample folders with hierarchy
    static func createFolderHierarchy(in context: ModelContext) -> [Folder] {
        // Create parent folders
        let workFolder = Folder(name: "Work", color: FolderColor.blue.rawValue, icon: FolderIcon.work.rawValue)
        let personalFolder = Folder(name: "Personal", color: FolderColor.green.rawValue, icon: FolderIcon.personal.rawValue)
        
        context.insert(workFolder)
        context.insert(personalFolder)
        
        // Create subfolders
        let projectsSubfolder = Folder(name: "Projects", color: FolderColor.purple.rawValue, icon: FolderIcon.projects.rawValue)
        let meetingsSubfolder = Folder(name: "Meetings", color: FolderColor.orange.rawValue, icon: FolderIcon.work.rawValue)
        
        projectsSubfolder.parentFolder = workFolder
        meetingsSubfolder.parentFolder = workFolder
        
        workFolder.subfolders.append(projectsSubfolder)
        workFolder.subfolders.append(meetingsSubfolder)
        
        context.insert(projectsSubfolder)
        context.insert(meetingsSubfolder)
        
        return [workFolder, personalFolder, projectsSubfolder, meetingsSubfolder]
    }
    
    /// Create sample tags with various colors
    static func createDiverseTags(in context: ModelContext) -> [Tag] {
        let tagData = [
            ("work", TagColor.blue),
            ("personal", TagColor.green),
            ("important", TagColor.red),
            ("urgent", TagColor.orange),
            ("idea", TagColor.yellow),
            ("meeting", TagColor.purple),
            ("project", TagColor.indigo),
            ("draft", TagColor.gray),
            ("review", TagColor.pink),
            ("learning", TagColor.cyan)
        ]
        
        var tags: [Tag] = []
        
        for (name, color) in tagData {
            let tag = Tag(name: name, color: color.rawValue)
            tag.usageCount = Int.random(in: 1...10) // Random usage for testing
            context.insert(tag)
            tags.append(tag)
        }
        
        return tags
    }
}

