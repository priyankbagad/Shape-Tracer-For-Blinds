# ShapeTracer

ShapeTracer is a SwiftUI app that enables blind and low-vision users to learn and practice shape tracing through voice guidance, audio feedback, and haptics. It also generates structured CSV logs to support research on motor skills, accessibility, and user interaction behavior.

---

## Problem

Blind users face challenges in learning gestures and tracing shapes due to the lack of real-time feedback in most applications. Existing solutions often do not integrate auditory, haptic, and data-driven features to make the experience inclusive and research-ready.

---

## Solution

- Quadrant-based shape selection (Square, Circle, Triangle, Star) with spoken hints.  
- Tap on the outline to establish a starting point before tracing.  
- Real-time auditory and haptic feedback:  
  - Pitch mapped to distance from the outline.  
  - Light tick when on-path.  
  - Stronger haptic and sound cue when vertices are reached.  
- Gesture-based controls:  
  - Triple-tap to reset tracing.  
  - Five-tap to return to the landing screen.  
- Eyes-Free mode with progress announcements (25%, 50%, 75%, 100%).  
- Automatic CSV logging of each attempt, including summary data, events, and raw touch samples.  

---

## Features

- Accessibility-first design with VoiceOver support and no reliance on visual-only controls.  
- Responsive layout that adapts to iPhone and iPad.  
- Integration of Core Haptics for tactile guidance.  
- CSV export via Share Sheet for easy access to logs.  

---

## Testing

Two unit tests have been added to ensure correctness of the core logic:  
- `PathHitTesterTests` validates detection of on-path vs. off-path points.  
- `VertexDetectionTests` validates vertex recognition and corresponding feedback triggers.  

Default UI tests for app launch and performance are also included.

---

## CSV Schema

The exported file `traces_study.csv` contains three row types:  

- **summary** – one per attempt, recording duration, success, and final coverage.  
- **event** – discrete milestones such as start, reset, progress percentages, vertex hits, and completion.  
- **sample** – raw time-series data capturing every touch point.

**Important columns include:**  
- `attempt_id`: unique identifier for each attempt  
- `participant_id`: anonymized user ID  
- `shape`: the traced shape  
- `duration_ms`: total attempt duration  
- `coverage_final`: percentage of shape outline covered  
- `onpath_time_ms` and `offpath_time_ms`: time spent on vs. off the outline  
- `event_type` and `event_value`: logged actions and progress milestones  
- `x`, `y`, `distance`, `onPath`, `vertexHit`: raw trace data  

---

## Screenshots

Include:  
- Landing screen with four selectable shapes  
- Tracing screen showing the outline and user path  
- Example CSV file opened in Excel or Numbers  

---

## How to Run

1. Open `ShapeTracer.xcodeproj` in Xcode 15 or later.  
2. Select a simulator or run on a physical iPhone for haptic feedback.  
3. Build and run the project.  
4. Select a shape and trace it using a finger.  
5. Use the "Export CSV" button to share logs via AirDrop, Mail, or Save to Files.  

---

## Research Applications

- Study of motor skill learning: analyzing speed, accuracy, and error correction during tracing.  
- Accessibility evaluation: comparing Eyes-Free mode against guided tracing.  
- Interaction analysis: studying resets, off-path errors, and vertex recognition.  

---

## Acknowledgments

This project was developed as part of a technical challenge to demonstrate:  
- SwiftUI development  
- Accessibility best practices  
- Audio and haptic integration  
- Data logging for research  
