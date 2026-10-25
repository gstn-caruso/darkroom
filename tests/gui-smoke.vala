// SPDX-License-Identifier: GPL-3.0-or-later
private void native_window () {
    try {
        // GTK must use the Xvfb display, not an inherited Wayland compositor.
        assert_cmpstr (Gdk.Display.get_default ().get_name (), CompareOperator.EQ,
            Environment.get_variable ("DISPLAY"));
        var application = new Darkroom.Application ();
        application.register (null);
        application.activate ();
        var window = application.active_window as Darkroom.MainWindow;
        assert_nonnull (window);
        assert_true (window.visible);
        assert_nonnull (window.lookup_action ("open"));
        assert_nonnull (window.lookup_action ("rotate"));
        assert_false (window.lookup_action ("rotate").enabled);
        assert_false (window.lookup_action ("reset").enabled);
        var directory = DirUtils.make_tmp ("darkroom-gui-XXXXXX");
        var path = Path.build_filename (directory, "photo.png");
        var photo = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 2, 3);
        photo.fill (0x123456ffU);
        photo.save (path, "png");
        window.load_photo (File.new_for_path (path));
        assert_nonnull (window.picture.paintable);
        assert_true (window.lookup_action ("rotate").enabled);
        assert_true (window.lookup_action ("reset").enabled);
        window.lookup_action ("rotate").activate (null);
        assert_cmpint (window.picture.paintable.get_intrinsic_width (), CompareOperator.EQ, 3);
        assert_cmpint (window.picture.paintable.get_intrinsic_height (), CompareOperator.EQ, 2);
        window.lookup_action ("reset").activate (null);
        assert_cmpint (window.picture.paintable.get_intrinsic_width (), CompareOperator.EQ, 2);
        FileUtils.remove (path);
        DirUtils.remove (directory);
        window.close ();
    } catch (Error error) {
        Test.fail_printf ("Unexpected error: %s", error.message);
    }
}

int main (string[] args) {
    Test.init (ref args);
    Adw.init ();
    Test.add_func ("/gui/native-window", native_window);
    return Test.run ();
}
