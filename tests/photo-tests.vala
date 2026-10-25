// SPDX-License-Identifier: GPL-3.0-or-later
private void loads_photo () {
    try {
        var directory = DirUtils.make_tmp ("darkroom-test-XXXXXX");
        var path = Path.build_filename (directory, "photo.png");
        var source = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 2, 3);
        source.fill (0xff0000ffU);
        source.save (path, "png");
        var preview = new Darkroom.PhotoPreview ();
        preview.open (path);
        assert_nonnull (preview.image);
        assert_cmpint (preview.image.width, CompareOperator.EQ, 2);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 3);
        FileUtils.remove (path);
        DirUtils.remove (directory);
    } catch (Error error) {
        Test.fail_printf ("Unexpected error: %s", error.message);
    }
}

private void rotates_without_writing () {
    try {
        var directory = DirUtils.make_tmp ("darkroom-test-XXXXXX");
        var path = Path.build_filename (directory, "photo.png");
        var source = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 2, 3);
        source.fill (0xff0000ffU);
        source.save (path, "png");
        // A green top-left pixel distinguishes clockwise from counterclockwise.
        source.get_pixels ()[0] = 0;
        source.get_pixels ()[1] = 255;
        source.save (path, "png");
        uint8[] before;
        FileUtils.get_data (path, out before);
        var preview = new Darkroom.PhotoPreview ();
        preview.open (path);
        preview.rotate_clockwise ();
        assert_cmpint (preview.image.width, CompareOperator.EQ, 3);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 2);
        assert_true (preview.image.get_pixels ()[6] == 0);
        assert_true (preview.image.get_pixels ()[7] == 255);
        for (int turn = 0; turn < 3; turn++) {
            preview.rotate_clockwise ();
        }
        assert_cmpint (preview.image.width, CompareOperator.EQ, 2);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 3);
        assert_true (preview.image.get_pixels ()[0] == 0);
        assert_true (preview.image.get_pixels ()[1] == 255);
        uint8[] after;
        FileUtils.get_data (path, out after);
        assert_cmpint (before.length, CompareOperator.EQ, after.length);
        for (int i = 0; i < before.length; i++) {
            assert_true (before[i] == after[i]);
        }
        FileUtils.remove (path);
        DirUtils.remove (directory);
    } catch (Error error) {
        Test.fail_printf ("Unexpected error: %s", error.message);
    }
}

private void resets_preview () {
    try {
        var directory = DirUtils.make_tmp ("darkroom-test-XXXXXX");
        var path = Path.build_filename (directory, "photo.png");
        var source = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 2, 3);
        source.fill (0xff0000ffU);
        source.get_pixels ()[0] = 0;
        source.get_pixels ()[1] = 255;
        source.save (path, "png");
        var preview = new Darkroom.PhotoPreview ();
        preview.open (path);
        preview.rotate_clockwise ();
        preview.reset ();
        assert_cmpint (preview.image.width, CompareOperator.EQ, 2);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 3);
        for (int y = 0; y < source.height; y++) {
            for (int byte = 0; byte < source.width * source.n_channels; byte++) {
                assert_true (source.get_pixels ()[y * source.rowstride + byte]
                    == preview.image.get_pixels ()[y * preview.image.rowstride + byte]);
            }
        }
        FileUtils.remove (path);
        DirUtils.remove (directory);
    } catch (Error error) {
        Test.fail_printf ("Unexpected error: %s", error.message);
    }
}

private void preserves_preview_on_failure () {
    try {
        var directory = DirUtils.make_tmp ("darkroom-test-XXXXXX");
        var path = Path.build_filename (directory, "photo.png");
        var source = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 2, 3);
        source.fill (0x123456ffU);
        source.save (path, "png");
        var preview = new Darkroom.PhotoPreview ();
        preview.open (path);
        preview.rotate_clockwise ();
        var previous = preview.image;
        try {
            preview.open (Path.build_filename (directory, "missing.jpg"));
            Test.fail_printf ("Missing input must be rejected");
        } catch (Error expected) {
            assert_true (preview.image == previous);
        }
        FileUtils.remove (path);
        DirUtils.remove (directory);
    } catch (Error error) {
        Test.fail_printf ("Unexpected error: %s", error.message);
    }
}

private void bounds_large_photo () {
    try {
        var directory = DirUtils.make_tmp ("darkroom-test-XXXXXX");
        var path = Path.build_filename (directory, "large.png");
        var source = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 3200, 800);
        source.fill (0x123456ffU);
        source.save (path, "png");
        var preview = new Darkroom.PhotoPreview ();
        preview.open (path);
        assert_cmpint (preview.image.width, CompareOperator.EQ, 1600);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 400);
        assert_cmpint (preview.image.get_pixels ()[0], CompareOperator.EQ, 0x12);
        FileUtils.remove (path);
        DirUtils.remove (directory);
    } catch (Error error) {
        Test.fail_printf ("Unexpected error: %s", error.message);
    }
}

private void honors_embedded_orientation () {
    try {
        var directory = DirUtils.make_tmp ("darkroom-test-XXXXXX");
        var path = Path.build_filename (directory, "oriented.jpg");
        var source = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 2, 3);
        source.fill (0x123456ffU);
        source.save (path, "jpeg");
        uint8[] jpeg;
        FileUtils.get_data (path, out jpeg);
        // JPEG APP1: Exif header, little-endian TIFF, one SHORT Orientation=6
        // entry (90 degrees clockwise), and no next image-file directory.
        uint8[] exif = {
            0xff, 0xe1, 0x00, 0x22, 0x45, 0x78, 0x69, 0x66, 0x00, 0x00,
            0x49, 0x49, 0x2a, 0x00, 0x08, 0x00, 0x00, 0x00, 0x01, 0x00,
            0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00,
            0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        };
        var oriented = new uint8[jpeg.length + exif.length];
        oriented[0] = jpeg[0];
        oriented[1] = jpeg[1];
        for (int i = 0; i < exif.length; i++) {
            oriented[i + 2] = exif[i];
        }
        for (int i = 2; i < jpeg.length; i++) {
            oriented[i + exif.length] = jpeg[i];
        }
        FileUtils.set_data (path, oriented);
        var preview = new Darkroom.PhotoPreview ();
        preview.open (path);
        assert_cmpint (preview.image.width, CompareOperator.EQ, 3);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 2);
        preview.rotate_clockwise ();
        preview.reset ();
        assert_cmpint (preview.image.width, CompareOperator.EQ, 3);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 2);
        FileUtils.remove (path);
        DirUtils.remove (directory);
    } catch (Error error) {
        Test.fail_printf ("Unexpected error: %s", error.message);
    }
}

private void new_photo_replaces_reset_baseline () {
    try {
        var directory = DirUtils.make_tmp ("darkroom-test-XXXXXX");
        var first_path = Path.build_filename (directory, "first.png");
        var second_path = Path.build_filename (directory, "second.png");
        var first = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 2, 3);
        first.fill (0xff0000ffU);
        first.save (first_path, "png");
        var second = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 4, 1);
        second.fill (0x00ff00ffU);
        second.save (second_path, "png");
        var preview = new Darkroom.PhotoPreview ();
        preview.open (first_path);
        preview.rotate_clockwise ();
        preview.open (second_path);
        assert_cmpint (preview.image.width, CompareOperator.EQ, 4);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 1);
        preview.rotate_clockwise ();
        preview.reset ();
        assert_cmpint (preview.image.width, CompareOperator.EQ, 4);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 1);
        assert_cmpint (preview.image.get_pixels ()[0], CompareOperator.EQ, 0);
        assert_cmpint (preview.image.get_pixels ()[1], CompareOperator.EQ, 255);
        FileUtils.remove (first_path);
        FileUtils.remove (second_path);
        DirUtils.remove (directory);
    } catch (Error error) {
        Test.fail_printf ("Unexpected error: %s", error.message);
    }
}

private void preserves_preview_on_decode_failure () {
    try {
        var directory = DirUtils.make_tmp ("darkroom-test-XXXXXX");
        var path = Path.build_filename (directory, "photo.png");
        var broken_path = Path.build_filename (directory, "truncated.png");
        var source = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 2, 3);
        source.fill (0x123456ffU);
        source.save (path, "png");
        uint8[] png;
        FileUtils.get_data (path, out png);
        // Keep the PNG signature and IHDR dimensions, but omit pixel data.
        FileUtils.set_data (broken_path, png[0:33]);
        var preview = new Darkroom.PhotoPreview ();
        preview.open (path);
        preview.rotate_clockwise ();
        var previous = preview.image;
        try {
            preview.open (broken_path);
            Test.fail_printf ("Truncated input must be rejected");
        } catch (Error expected) {
            assert_true (preview.image == previous);
        }
        preview.reset ();
        assert_cmpint (preview.image.width, CompareOperator.EQ, 2);
        assert_cmpint (preview.image.height, CompareOperator.EQ, 3);
        assert_cmpint (preview.image.get_pixels ()[0], CompareOperator.EQ, 0x12);
        FileUtils.remove (path);
        FileUtils.remove (broken_path);
        DirUtils.remove (directory);
    } catch (Error error) {
        Test.fail_printf ("Unexpected error: %s", error.message);
    }
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/preview/loads-photo", loads_photo);
    Test.add_func ("/preview/rotates-without-writing", rotates_without_writing);
    Test.add_func ("/preview/resets-preview", resets_preview);
    Test.add_func ("/preview/preserves-on-failure", preserves_preview_on_failure);
    Test.add_func ("/preview/bounds-large-photo", bounds_large_photo);
    Test.add_func ("/preview/honors-embedded-orientation", honors_embedded_orientation);
    Test.add_func ("/preview/new-photo-replaces-reset-baseline", new_photo_replaces_reset_baseline);
    Test.add_func ("/preview/preserves-on-decode-failure", preserves_preview_on_decode_failure);
    return Test.run ();
}
