// SPDX-License-Identifier: GPL-3.0-or-later
namespace Darkroom {
    public class MainWindow : Adw.ApplicationWindow {
        public Gtk.Picture picture { get; private set; }
        private PhotoPreview preview = new PhotoPreview ();
        private Gtk.Stack pages = new Gtk.Stack ();
        private Gtk.Label message = new Gtk.Label ("Preview edits only. Your original stays unchanged.");
        private SimpleAction rotate_action = new SimpleAction ("rotate", null);
        private SimpleAction reset_action = new SimpleAction ("reset", null);

        public MainWindow (Gtk.Application application) {
            Object (application: application, title: "Darkroom", default_width: 1000, default_height: 700);
            var open_action = new SimpleAction ("open", null);
            open_action.activate.connect (choose_photo);
            add_action (open_action);
            rotate_action.set_enabled (false);
            reset_action.set_enabled (false);
            rotate_action.activate.connect (() => {
                preview.rotate_clockwise ();
                refresh_preview ();
            });
            reset_action.activate.connect (() => {
                preview.reset ();
                refresh_preview ();
            });
            add_action (rotate_action);
            add_action (reset_action);

            var header = new Adw.HeaderBar ();
            var open_button = new Gtk.Button.with_label ("Open Photo");
            open_button.action_name = "win.open";
            header.pack_start (open_button);
            var rotate_button = new Gtk.Button.with_label ("Rotate Clockwise");
            rotate_button.action_name = "win.rotate";
            header.pack_end (rotate_button);
            var reset_button = new Gtk.Button.with_label ("Reset");
            reset_button.action_name = "win.reset";
            header.pack_end (reset_button);

            var empty = new Adw.StatusPage ();
            empty.title = "Open a Photo";
            empty.description = "Preview and rotate a photo without changing the original.";
            empty.icon_name = "image-x-generic-symbolic";
            picture = new Gtk.Picture ();
            picture.can_shrink = true;
            picture.content_fit = Gtk.ContentFit.CONTAIN;
            picture.accessible_role = Gtk.AccessibleRole.IMG;
            pages.add_named (empty, "empty");
            pages.add_named (picture, "photo");
            pages.vexpand = true;
            message.wrap = true;
            message.margin_top = 8;
            message.margin_bottom = 8;
            message.margin_start = 12;
            message.margin_end = 12;
            var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            layout.append (header);
            layout.append (pages);
            layout.append (message);
            content = layout;
        }

        private void choose_photo () {
            var filter = new Gtk.FileFilter ();
            filter.name = "Photos (JPEG, PNG, TIFF, WebP)";
            filter.add_mime_type ("image/jpeg");
            filter.add_mime_type ("image/png");
            filter.add_mime_type ("image/tiff");
            filter.add_mime_type ("image/webp");
            var filters = new ListStore (typeof (Gtk.FileFilter));
            filters.append (filter);
            var dialog = new Gtk.FileDialog ();
            dialog.title = "Open Photo";
            dialog.filters = filters;
            dialog.open.begin (this, null, (object, result) => {
                try {
                    load_photo (dialog.open.end (result));
                } catch (Gtk.DialogError.DISMISSED error) {
                    // Closing the chooser leaves the current preview untouched.
                } catch (Error error) {
                    message.label = "Could not open photo: " + error.message;
                }
            });
        }

        public void load_photo (File file) throws Error {
            var path = file.get_path ();
            if (path == null) {
                throw new IOError.NOT_SUPPORTED ("Only local photos are supported.");
            }
            preview.open (path);
            refresh_preview ();
            title = "Darkroom — " + file.get_basename ();
            message.label = "Preview edits only. Your original stays unchanged.";
        }

        private void refresh_preview () {
            picture.paintable = Gdk.Texture.for_pixbuf (preview.image);
            pages.visible_child_name = "photo";
            rotate_action.set_enabled (true);
            reset_action.set_enabled (true);
        }
    }
}
