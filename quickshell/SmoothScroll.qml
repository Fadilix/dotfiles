import QtQuick

// Scrolling with momentum for a ListView or GridView, like a web page:
// the touchpad follows your fingers, keeps coasting after they lift, then slows to a stop.
// Mouse wheel notches glide instead of jumping.
// Declare it inside the view with parent set to the view: it lies over the items, catches
// only scroll events, and lets clicks and hovering through to the items underneath.
MouseArea {
    id: h

    required property Flickable flickable
    anchors.fill: parent
    z: 10
    acceptedButtons: Qt.NoButton
    hoverEnabled: false
    property real wheelStep: 120          // pixels per mouse wheel notch
    property real friction: 1.0           // higher stops sooner

    property real velocity: 0             // px/s, positive means content moves down
    property double lastTime: 0


    function maxY() { return flickable.originY + Math.max(0, flickable.contentHeight - flickable.height) }
    function clampY(y) { return Math.max(flickable.originY, Math.min(y, maxY())) }

    function coast() {
        var v = velocity
        velocity = 0
        if (Math.abs(v) < 120) return
        // Ease-out cubic starts at 3 * distance / duration, so this keeps the release speed.
        var duration = Math.max(450, Math.min(1800, Math.abs(v) * 0.7 / friction))
        glide.stop()
        glide.easing.type = Easing.OutCubic
        glide.duration = duration
        glide.to = clampY(flickable.contentY - v * duration / 3000)
        glide.start()
    }

    NumberAnimation { id: glide; target: h.flickable; property: "contentY" }
    Timer { id: release; interval: 60; onTriggered: h.coast() }

    onWheel: event => {
        var px = event.pixelDelta.y
        if (px !== 0) {
            // Touchpad: move 1:1 and track the speed for the coast after release.
            glide.stop()
            var now = Date.now(), dt = now - lastTime
            var v = px / Math.max(dt, 4) * 1000
            velocity = (dt > 80 || Math.sign(v) !== Math.sign(velocity)) ? v : velocity * 0.5 + v * 0.5
            lastTime = now
            flickable.contentY = clampY(flickable.contentY - px)
            release.restart()
        } else if (event.angleDelta.y !== 0) {
            // Mouse wheel: glide one step per notch; quick notches add up.
            var from = glide.running ? glide.to : flickable.contentY
            glide.stop()
            glide.easing.type = Easing.OutCubic
            glide.duration = 260
            glide.to = clampY(from - event.angleDelta.y / 120 * wheelStep)
            glide.start()
        } else {
            // Fingers lifted (zero-length scroll event): coast right away.
            release.stop()
            coast()
        }
        event.accepted = true
    }
}
