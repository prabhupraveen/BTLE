Setting up an RTL project, defining the target FPGA, importing a large batch of Verilog source files, setting the top module, and preparing the simulation/synthesis environment.

Here are the first 8 steps to get the project created and your sources imported via the Vivado GUI.

### **Phase 1: Project Creation and Source Setup**

**Step 1: Open Vivado**

* **Action:** Launch the Vivado IDE on your machine.
* **Expected Output:** The Vivado Start Page (Quick Start menu) appears.

**Step 2: Initialize New Project Wizard**

* **Action:** Under "Tasks" or in the "File" menu, select **Project > New**. Click **Next** on the introductory screen.
* **Expected Output:** The "Project Name" screen appears.

**Step 3: Define Project Name and Location**

* **Action:** Enter `btle_controller` as the Project Name. Choose the directory where your source files are located (or a dedicated workspace folder). Check "Create project subdirectory". Click **Next**.
* **Expected Output:** The "Project Type" screen appears.

**Step 4: Select Project Type**

* **Action:** Select **RTL Project**. Check the box that says **"Do not specify sources at this time"** (we will add them manually once the workspace loads, which mirrors the script's behavior). Click **Next**.
* **Expected Output:** The "Default Part" screen appears.

**Step 5: Select Target FPGA Part**

* **Action:** Switch to the **Parts** tab. In the "Search" field, type `xc7z020clg484-1`. Select the exact part when it filters down in the list below. Click **Next**, review the summary, and click **Finish**.
* **Expected Output:** Vivado initializes the project and opens the main workspace environment.

**Step 6: Configure Project Settings (Target Language)**

* **Action:** Click the **Settings** gear icon in the Flow Navigator (on the left side). Under **Project Settings > General**, ensure the **Target language** is set to **Verilog**. Click **OK**.
* **Expected Output:** The project is strictly configured for Verilog generation.

**Step 7: Add Design Sources**

* **Action:** In the Flow Navigator under "Project Manager", click **Add Sources**. Select **Add or create design sources** and click **Next**. Click **Add Files**, browse to your source directory, and select all the `.v` files listed in your script (e.g., `btle_controller.v`, `btle_ll.v`, `crc24.v`, `vco.v`, etc.). Ensure "Copy sources into project" is *unchecked* if you want to keep them relative (as the script does). Click **Finish**.
* **Expected Output:** Vivado scans the files and populates the "Sources" window.

**Step 8: Set the Top Module**

* **Action:** In the "Sources" window, expand the "Design Sources" folder. Right-click the `btle_controller.v` file and select **Set as Top**.
* **Expected Output:** The `btle_controller` module will move to the top of the hierarchy tree and its icon will turn bold with a green hierarchy symbol.

---

### **Phase 2: Configuration, Execution, and Script Export**

**Step 9: Configure Simulation Settings** (Defaults, but check)

* **Action:** Click the **Settings** gear in the Flow Navigator. Go to **Simulation**. Under the "Simulation" tab, ensure the Simulator is set to **Vivado Simulator (XSim)**. Click on the **Elaboration** tab and verify the default radix. Click on the **Simulation** tab and set the `xsim.simulate.runtime` to `1000ns`. Click **OK**.
* **Expected Output:** The Vivado simulator is primed to run a 1-microsecond simulation by default.

**Step 10: Configure Synthesis Settings** (Defaults, but check)

* **Action:** Open **Settings** again and navigate to **Synthesis**. Ensure the Strategy is "Vivado Synthesis Defaults". Scroll through the options and verify/set the following to match the script:
* `flatten_hierarchy`: **rebuilt**
* `gated_clock_conversion`: **off**
* `bufg`: **12**
* `fsm_extraction`: **auto**
* `shreg_min_size`: **3**


* **Expected Output:** Vivado's synthesis engine is now constrained to the exact resource and optimization limits defined in your original script.

**Step 11: Configure Implementation Settings** (Defaults, but check)

* **Action:** In the same **Settings** window, click **Implementation**. Ensure the Strategy is "Vivado Implementation Defaults". Look at the steps checklist. Make sure **Opt Design** (opt_design) and **Phys Opt Design** (phys_opt_design) are checked/enabled. Make sure **Power Opt Design** is disabled. Click **OK**.
* **Expected Output:** The implementation flow is configured to include physical logic optimization but skip power optimization.


### **Phase 2.5: Final Tweaks Before Saving**

**Step 13: Downgrade the NSTD-1 DRC Check**

* **Action:** In the Vivado top menu, go to **Tools > Settings**.
* **Action Details:** * In the left pane of the Settings window, expand **Project** and click on **DRC**.
* In the search box within that pane, type `NSTD-1`.
* You should see the rule `NSTD-1` (Unspecified I/O Standard).
* Click on the "Severity" dropdown next to it and change it to **Warning**.
* Click **OK**.


* **Expected Output:** Vivado will no longer halt or throw critical errors regarding unassigned pins for this specific project.

**Step 14: Save the Auto-generated TCL Script**

* **Action:** Go to **File > Project > Write tcl...**.
* **Action Details:** Name it something like `my_btle_controller.tcl`. Ensure "Copy sources to new project" is unchecked so it maintains the relative paths just like the original script.
* **Expected Output:** You will get a `.tcl` file in your directory. If you open it in a text editor, you'll see it strongly resembles the original `btle_controller.tcl` file, proving you've successfully reverse-engineered the GUI steps!

