#include <gio/gio.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <url>\n", argv[0]);
        return 1;
    }

    const gchar *url = argv[1];
    const gchar *package = ""; // aucun package

    GError *error = NULL;

    GDBusConnection *bus = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &error);
    if (error != NULL) {
        fprintf(stderr, "Failed to connect to session bus: %s\n", error->message);
        g_error_free(error);
        return 1;
    }

    g_dbus_connection_call_sync(
        bus,
        "com.lomiri.URLDispatcher",
        "/com/lomiri/URLDispatcher",
        "com.lomiri.URLDispatcher",
        "DispatchURL",
        g_variant_new("(ss)", url, package),
        NULL,
        G_DBUS_CALL_FLAGS_NONE,
        -1,
        NULL,
        &error
    );

    if (error != NULL) {
        fprintf(stderr, "D-Bus call failed: %s\n", error->message);
        g_error_free(error);
        g_object_unref(bus);
        return 1;
    }

    g_dbus_connection_flush_sync(bus, NULL, NULL);
    g_object_unref(bus);

    return 0;
}
