"""Add the Android TTS visibility query to Godot APK templates (stdlib only).

Preserves existing binary XML string indexes and all other manifest nodes.
Godot aligns and signs the final application during its normal export.
"""
import argparse
from pathlib import Path
import shutil
import struct
import zipfile

NONE = 0xFFFFFFFF
ACTION = "android.intent.action.TTS_SERVICE"
ANDROID = "http://schemas.android.com/apk/res/android"


def _length(data, position, utf8):
    if utf8:
        value = data[position]
        return (((value & 127) << 8) | data[position + 1], position + 2) if value & 128 else (value, position + 1)
    value = struct.unpack_from("<H", data, position)[0]
    return (((value & 32767) << 16) | struct.unpack_from("<H", data, position + 2)[0], position + 4) if value & 32768 else (value, position + 2)


def _size8(value):
    return bytes([value]) if value < 128 else bytes([(value >> 8) | 128, value & 255])


def patch_manifest(data):
    kind, header, size = struct.unpack_from("<HHI", data)
    if kind != 3 or header != 8 or size != len(data):
        raise ValueError("Not a complete Android binary XML manifest")
    chunks = []
    position = header
    while position < size:
        chunk_kind, chunk_header, chunk_size = struct.unpack_from("<HHI", data, position)
        if chunk_size < chunk_header or position + chunk_size > size:
            raise ValueError("Invalid binary XML chunk")
        chunks.append((chunk_kind, data[position:position + chunk_size]))
        position += chunk_size
    pool_index = next(i for i, (k, _) in enumerate(chunks) if k == 1)
    pool = chunks[pool_index][1]
    count, styles, flags, start, style_start = struct.unpack_from("<IIIII", pool, 8)
    if styles or style_start or struct.unpack_from("<H", pool, 2)[0] != 28:
        raise ValueError("Styled manifest string pools are unsupported")
    utf8 = bool(flags & 256)
    offsets = list(struct.unpack_from("<" + "I" * count, pool, 28))
    strings = []
    for offset in offsets:
        length, cursor = _length(pool, start + offset, utf8)
        if utf8:
            length, cursor = _length(pool, cursor, True)
            strings.append(pool[cursor:cursor + length].decode("utf-8"))
        else:
            strings.append(pool[cursor:cursor + length * 2].decode("utf-16le"))
    # Idempotence: verify the action value, rather than just its presence in the pool.
    for k, node in chunks:
        if k != 0x102:
            continue
        name = struct.unpack_from("<I", node, 20)[0]
        if strings[name] != "action":
            continue
        attr_start, attr_size, attr_count = struct.unpack_from("<HHH", node, 24)
        for n in range(attr_count):
            attr = 16 + attr_start + n * attr_size
            raw = struct.unpack_from("<I", node, attr + 8)[0]
            typed = struct.unpack_from("<I", node, attr + 16)[0]
            if (raw != NONE and strings[raw] == ACTION) or (node[attr + 15] == 3 and strings[typed] == ACTION):
                return data
    payload = bytearray(pool[start:])
    def index(text):
        if text in strings:
            return strings.index(text)
        encoded = text.encode("utf-8" if utf8 else "utf-16le")
        offsets.append(len(payload))
        if utf8:
            payload.extend(_size8(len(text)) + _size8(len(encoded)) + encoded + b"\0")
        else:
            payload.extend(struct.pack("<H", len(encoded) // 2) + encoded + b"\0\0")
        strings.append(text)
        return len(strings) - 1
    queries, intent, action, value = [index(x) for x in ["queries", "intent", "action", ACTION]]
    ns = index(ANDROID)
    name_attr = index("name")
    def begin(name, attribute=b""):
        count = 1 if attribute else 0
        return struct.pack("<HHIII", 0x102, 16, 36 + len(attribute), 0, NONE) + struct.pack("<IIHHHHHH", NONE, name, 20, 20, count, 0, 0, 0) + attribute
    def end(name):
        return struct.pack("<HHIIIII", 0x103, 16, 24, 0, NONE, NONE, name)
    attribute = struct.pack("<IIIHBBI", ns, name_attr, value, 8, 0, 3, value)
    insertion = begin(intent) + begin(action, attribute) + end(action) + end(intent)
    at = next((i for i, (k, node) in enumerate(chunks) if k == 0x103 and strings[struct.unpack_from("<I", node, 20)[0]] == "queries"), None)
    if at is None:
        at = next(i for i, (k, node) in enumerate(chunks) if k == 0x102 and strings[struct.unpack_from("<I", node, 20)[0]] == "application")
        insertion = begin(queries) + insertion + end(queries)
    payload.extend(b"\0" * (-len(payload) % 4))
    string_start = 28 + 4 * len(strings)
    new_pool = struct.pack("<HHIIIIII", 1, 28, string_start + len(payload), len(strings), 0, flags & ~1, string_start, 0) + struct.pack("<" + "I" * len(offsets), *offsets) + payload
    chunks[pool_index] = (1, new_pool)
    chunks.insert(at, (0, insertion))
    body = b"".join(chunk for _, chunk in chunks)
    return struct.pack("<HHI", 3, 8, 8 + len(body)) + body


def prepare(source, destination):
    if source.resolve() == destination.resolve():
        raise ValueError("Keep the official template unchanged; use a separate output folder")
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(".tmp")
    with zipfile.ZipFile(source) as original:
        manifest = patch_manifest(original.read("AndroidManifest.xml"))
        assert patch_manifest(manifest) == manifest
        with zipfile.ZipFile(temporary, "w") as output:
            for entry in original.infolist():
                name = entry.filename
                if name.startswith("META-INF/") and (name.endswith((".SF", ".RSA", ".DSA", ".EC")) or name == "META-INF/MANIFEST.MF"):
                    continue
                if name == "AndroidManifest.xml":
                    output.writestr(entry, manifest)
                else:
                    with original.open(entry) as src, output.open(entry, "w") as dst:
                        shutil.copyfileobj(src, dst, 1024 * 1024)
    temporary.replace(destination)
    print("TTS_TEMPLATE_READY", destination.name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("templates_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    for filename in ["android_debug.apk", "android_release.apk"]:
        prepare(args.templates_dir / filename, args.output_dir / filename)
