import re
import os


class VerilogWikiParser(object):

    def __init__(self, root_dir):
        self.root_dir = root_dir
        self.modules = {}  # module_name -> {file, calls, ports}
        self.called_by = {}  # module_name -> list of parents

    # -------------------------
    # CLEAN COMMENTS
    # -------------------------
    def clean(self, text):
        text = re.sub(r"//[^\n]*", "\n", text)
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
        return text

    # -------------------------
    # MODULE + PORT PARSING
    # -------------------------
    def extract_module_and_ports(self, text):
        pattern = r"module\s+(\w+)\s*(#\s*\(.*?\))?\s*\((.*?)\)\s*;"
        m = re.search(pattern, text, flags=re.S)

        if not m:
            return None

        mod_name = m.group(1)
        port_block = m.group(3)

        inputs = []
        outputs = []
        inouts = []

        ports = re.split(r",\s*\n|,\s*", port_block)

        for p in ports:
            p = p.strip()
            if not p:
                continue

            if p.startswith("input"):
                inputs.append(p.split()[-1])

            elif p.startswith("output"):
                outputs.append(p.split()[-1])

            elif p.startswith("inout"):
                inouts.append(p.split()[-1])

        return {
            "name": mod_name,
            "inputs": inputs,
            "outputs": outputs,
            "inouts": inouts
        }

    def build_called_by(self):
        # initialize
        for mod in self.modules:
            self.called_by[mod] = []

        # invert edges
        for caller, data in self.modules.items():
            for callee in data["calls"]:
                if callee in self.called_by:
                    self.called_by[callee].append(caller)

        # sort for readability
        for mod in self.called_by:
            self.called_by[mod] = sorted(self.called_by[mod])

    # -------------------------
    # REMOVE MODULE HEADER
    # -------------------------
    def remove_module_header(self, text):
        return re.sub(r"\bmodule\s+\w+.*?;\s*", "", text, flags=re.S)

    # -------------------------
    # INSTANTIATION PARSING
    # -------------------------
    def extract_calls(self, text, known_modules, current_module):
        calls = set()

        text = self.remove_module_header(text)

        # Matches: module_name #(params) instance_name (
        pattern = r"\b(\w+)\s*(?:#\s*\(.*?\))?\s+\w+\s*\("

        matches = re.finditer(pattern, text, flags=re.S)

        for m in matches:
            mod_name = m.group(1)

            if mod_name in known_modules and mod_name != current_module:
                calls.add(mod_name)

        return sorted(list(calls))

    # -------------------------
    # MAIN SCAN
    # -------------------------
    def scan(self):
        file_texts = {}

        # PASS 1: collect modules
        for root, _, files in os.walk(self.root_dir):
            for f in files:
                if not f.endswith(".v"):
                    continue

                if f.endswith("_tb.v"):
                    continue

                path = os.path.join(root, f)

                with open(path, "r") as fh:
                    raw = fh.read()
                    text = self.clean(raw)

                file_texts[path] = text

                mod = self.extract_module_and_ports(text)
                if not mod:
                    continue

                self.modules[mod["name"]] = {
                    "file": path,
                    "calls": [],
                    "inputs": mod["inputs"],
                    "outputs": mod["outputs"],
                    "inouts": mod["inouts"]
                }

        known_modules = set(self.modules.keys())

        # PASS 2: extract calls
        for path, text in file_texts.items():
            mod = self.extract_module_and_ports(text)
            if not mod:
                continue

            mod_name = mod["name"]

            calls = self.extract_calls(text, known_modules, mod_name)
            self.modules[mod_name]["calls"] = calls

        self.build_called_by()

    # -------------------------
    # MARKDOWN GENERATION
    # -------------------------
    def generate_markdown(self, out_dir="temp/docs/modules"):
        os.makedirs(out_dir, exist_ok=True)

        for mod, data in self.modules.items():
            fname = os.path.join(out_dir, f"{mod}.md")

            with open(fname, "w") as f:
                f.write(f"# {mod}\n\n")

                f.write("## Description\n")
                f.write("TODO: Add description\n\n")

                f.write("## Inputs\n")
                for p in data["inputs"]:
                    f.write(f"- {p}\n")

                f.write("\n## Outputs\n")
                for p in data["outputs"]:
                    f.write(f"- {p}\n")

                if data["inouts"]:
                    f.write("\n## Inouts\n")
                    for p in data["inouts"]:
                        f.write(f"- {p}\n")

                f.write("\n## Calls\n")
                for c in data["calls"]:
                    f.write(f"- [{c}]({c}.md)\n")

                f.write("\n## Called By\n")
                parents = self.called_by.get(mod, [])
                if not parents:
                    f.write("- None\n")
                else:
                    for p in parents:
                        f.write(f"- [{p}]({p}.md)\n")


# -------------------------
# ENTRY POINT
# -------------------------
if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python vwiki_full.py <verilog_root_dir>")
        exit(1)

    parser = VerilogWikiParser(sys.argv[1])
    parser.scan()
    parser.generate_markdown()

    print("Done.")
