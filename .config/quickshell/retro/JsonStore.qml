import Quickshell.Io

// A JSON file of shell state under the state directory (see Settings for
// why that is where it lives). The JsonAdapter inside is the schema. Live
// by default: every change to the adapter is written straight back, and an
// edit to the file from outside is read in. A store that writes on its own
// terms (`live: false`) is read once and written only through writeAdapter().
//
// `ready` fires once the file has been read, or found missing, so an owner
// that restores state from it has one place to do so.
FileView {
    id: root

    required property string dir
    required property string name
    property bool live: true

    signal ready

    path: root.dir + "/" + root.name
    watchChanges: root.live
    printErrors: false

    onFileChanged: reload()
    onAdapterUpdated: {
        if (root.live)
            writeAdapter();
    }
    onLoaded: root.ready()
    onLoadFailed: (error) => {
        if (error !== FileViewError.FileNotFound)
            return;
        // First run: materialise the defaults so the file is discoverable.
        if (root.live)
            writeAdapter();
        root.ready();
    }

    // FileView will not create intermediate directories. A property, not a
    // child: FileView's default slot is its adapter.
    readonly property Process mkdir: Process {
        running: true
        command: ["mkdir", "-p", root.dir]
        // Process.exited carries a QProcess::ExitStatus that Quickshell does
        // not expose to QML, so qmllint cannot type the handler.
        onExited: root.reload() // qmllint disable signal-handler-parameters
    }
}
