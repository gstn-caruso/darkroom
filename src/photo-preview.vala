// SPDX-License-Identifier: GPL-3.0-or-later
namespace Darkroom {
    public class PhotoPreview : Object {
        public Gdk.Pixbuf? image { get; private set; }
        private Gdk.Pixbuf? original;

        public void reset () {
            image = original;
        }

        public void rotate_clockwise () {
            if (image != null) {
                image = image.rotate_simple (Gdk.PixbufRotation.CLOCKWISE);
            }
        }

        public void open (string path) throws Error {
            int width;
            int height;
            if (Gdk.Pixbuf.get_file_info (path, out width, out height) == null) {
                throw new IOError.INVALID_DATA ("The file is not a supported photo.");
            }
            image = new Gdk.Pixbuf.from_file_at_scale (
                path, int.min (width, 1600), int.min (height, 1600), true
            ).apply_embedded_orientation ();
            original = image;
        }
    }
}
