import os
import sys
import vitis

# -----------------------------------------------------------------------------
# Arguments from shell
#   argv[1] = build directory
#   argv[2] = xsa filename (already copied into build dir)
# -----------------------------------------------------------------------------
if len(sys.argv) != 3:
    print("Usage: vitis -s build_fsbl.py <build_dir> <xsa_filename>")
    sys.exit(1)

build_dir = sys.argv[1]
xsa_name  = sys.argv[2]

workspace = os.path.join(build_dir, "build", "sdk")
xsa_path  = os.path.join(build_dir, xsa_name)

print("====================================================")
print("Vitis FSBL build")
print("Build dir :", build_dir)
print("Workspace :", workspace)
print("XSA       :", xsa_path)
print("====================================================")

if not os.path.isfile(xsa_path):
    raise RuntimeError(f"XSA not found: {xsa_path}")

# -----------------------------------------------------------------------------
# Create Vitis client
# -----------------------------------------------------------------------------
client = vitis.create_client()
client.set_workspace(path=workspace)

# -----------------------------------------------------------------------------
# Discover processors from XSA (protobuf based API)
# -----------------------------------------------------------------------------
print("\nQuerying processors from XSA...")

proc_obj = client.get_processor_os_list(xsa=xsa_path)

fields = proc_obj.ListFields()
if not fields:
    raise RuntimeError("OSProcessorList has no populated fields")

print("Raw protobuf fields:", [f[0].name for f in fields])

# Find the os_processors field explicitly
os_proc_entries = None
for field_desc, value in fields:
    if field_desc.name == "os_processors":
        os_proc_entries = value
        break

if os_proc_entries is None:
    raise RuntimeError("os_processors field not found in OSProcessorList")

if not os_proc_entries:
    raise RuntimeError("os_processors list is empty")

def normalize_value(val):
    """
    Normalize protobuf values into Python types:
      - RepeatedScalarContainer → list
      - string → string
    """
    try:
        # protobuf repeated container behaves like iterable but is not list
        if hasattr(val, "__len__") and not isinstance(val, (str, bytes)):
            return list(val)
    except Exception:
        pass

    return val


processors = []

for entry in os_proc_entries:
    proc_name = None
    os_name = None

    entry_fields = entry.ListFields()

    for fdesc, val in entry_fields:
        fname = fdesc.name
        val = normalize_value(val)

        if fname == "cpuInstance":
            # cpuInstance may be list: ["ps7_cortexa9_0", "ps7_cortexa9_1"]
            if isinstance(val, list) and len(val) > 0:
                proc_name = val[0]     # choose first CPU
            else:
                proc_name = val

        elif fname == "os":
            # os is string like "standalone"
            os_name = val

    if proc_name is None or os_name is None:
        raise RuntimeError(
            f"Unable to determine processor/os from entry fields: "
            f"{[f.name for f, _ in entry_fields]}"
        )

    processors.append((proc_name, os_name))

print("Available processors:")
for proc, os_name in processors:
    print(f"  - {proc} (OS: {os_name})")

# -----------------------------------------------------------------------------
# Select processor deterministically
# -----------------------------------------------------------------------------
# Prefer standalone FSBL
selected_proc = None
for proc, os_name in processors:
    if os_name == "standalone" and proc.endswith("_0"):
        selected_proc = proc
        break

if selected_proc is None:
    raise RuntimeError("No suitable standalone processor found")

print(f"Selected processor: {selected_proc}")

# -----------------------------------------------------------------------------
# Create platform component
# -----------------------------------------------------------------------------
print("\nCreating platform component...")

platform = client.create_platform_component(
    name="hw0",
    hw_design=xsa_path,
    cpu=selected_proc,
    os="standalone"
)

# -----------------------------------------------------------------------------
# Build platform (generates FSBL + platform artifacts)
# -----------------------------------------------------------------------------
print("\nBuilding platform (this may take a while)...")
platform.build()

try:
    print("\nPlatform output:", platform.get_output())
except Exception:
    pass

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
vitis.dispose()

print("\n====================================================")
print("FSBL platform build completed successfully.")
print("====================================================")