// SPDX-License-Identifier: GPL-3.0-or-later
namespace Darkroom {
    public class Application : Adw.Application {
        public Application () {
            Object (application_id: "org.darkroom.Darkroom", flags: ApplicationFlags.DEFAULT_FLAGS);
        }

        protected override void activate () {
            if (active_window == null) {
                new MainWindow (this).present ();
            } else {
                active_window.present ();
            }
        }
    }
}
