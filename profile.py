"""
Profile for our CSCI 555L project

Instructions:
Wait for the experiment to start, and then log into one or more of the nodes
by clicking on them in the toplogy, and choosing the `shell` menu option.
Use `sudo` to run root commands.
"""

# Import the Portal object.
import geni.portal as portal
import geni.rspec.pg as rspec
# Import the ProtoGENI library.
# Emulab specific extensions.
import geni.rspec.emulab as emulab

# Create a portal context, needed to defined parameters
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()


# Ubuntu 22.04
# osImage = ('urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU22-64-STD', 'UBUNTU 22.04')
osImage = 'urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU22-64-STD'

# Physical type for all nodes
# This is a parameter we will enter
pc.defineParameter("phystype",  "REQUIRED physical node type (eg m400)",
                   portal.ParameterType.STRING, "",
                   longDescription="Specify a single physical node type (pc3000,d710,etc) " +
                   "instead of letting the resource mapper choose for you.")

pc.defineParameter("workercount",  "REQUIRED number of workers (eg 3)",
                   portal.ParameterType.INTEGER, 3,
                   longDescription="Specify the number of worker nodes")

pc.defineParameter("clientcount",  "REQUIRED number of clients (eg 1)",
                   portal.ParameterType.INTEGER, 1,
                   longDescription="Specify the number of client nodes")

# Start VNC, why not
# "There will be a menu option in the node context menu to start a browser based VNC client"
startVNC = True


# For now, not setting link speed manually
# Optional link speed, normally the resource mapper will choose for you based on node availability
"""
pc.defineParameter("linkSpeed", "Link Speed",portal.ParameterType.INTEGER, 0,
                   [(0,"Any"),(100000,"100Mb/s"),(1000000,"1Gb/s"),(10000000,"10Gb/s"),(25000000,"25Gb/s"),(100000000,"100Gb/s")],
                   advanced=True,
                   longDescription="A specific link speed to use for your lan. Normally the resource " +
                   "mapper will choose for you based on node availability and the optional physical type.")

# For very large lans you might to tell the resource mapper to override the bandwidth constraints
# and treat it a "best-effort"
pc.defineParameter("bestEffort",  "Best Effort", portal.ParameterType.BOOLEAN, False,
                    advanced=True,
                    longDescription="For very large lans, you might get an error saying 'not enough bandwidth.' " +
                    "This options tells the resource mapper to ignore bandwidth and assume you know what you " +
                    "are doing, just give me the lan I ask for (if enough nodes are available).")
"""

# Require all nodes on the same switch, for replicability
# Note that this option can make it impossible for your experiment to map.
sameSwitch = True

# Retrieve the values the user specifies during instantiation.
# This is just the hardware type
params = pc.bindParameters()

# Check parameter validity.
if params.phystype != "":
    tokens = params.phystype.split(",")
    if len(tokens) != 1:
        pc.reportError(portal.ParameterError("Only a single type is allowed", ["phystype"]))

pc.verifyParameters()

# Create link/lan.
lan = request.LAN()
if sameSwitch:
	lan.setNoInterSwitchLinks()

""" This is for the currently unused option to request a set bandwidth
    if params.bestEffort:
        lan.best_effort = True
    elif params.linkSpeed > 0:
        lan.bandwidth = params.linkSpeed
"""

worker_count = params.workercount
client_count = params.clientcount
nodeCount = worker_count + client_count + 1

# Process nodes, adding to link or lan.
for i in range(nodeCount):
    # Create a node and add it to the request
    name = ''
    if i == 0:
        name = "master"
    elif i <= worker_count:
        name = "worker_" + str(i)
    else:
        name = "client_" + str(i - worker_count)
    node = request.RawPC(name)
    node.disk_image = osImage

    # Add to lan
    if nodeCount > 1:
        iface = node.addInterface("eth1")
        ip_address_suffix = str(100 + i)
        iface.addAddress(rspec.IPv4Address("10.10.1." + ip_address_suffix, "255.255.255.0"))
        lan.addInterface(iface)
    # Optional hardware type.
    if params.phystype != "":
        node.hardware_type = params.phystype
        # Set an environment variable to the hardware type.
        # node.addService(rspec.Execute(shell="bash", command="export HWTYPE=" + params.phystype))
        pass
    # Install and start X11 VNC. Calling this informs the Portal that you want a VNC
    # option in the node context menu to create a browser VNC client.
    #
    # If you prefer to start the VNC server yourself (on port 5901) then add nostart=True.
    #
    if startVNC:
        node.startVNC()
        pass
    pass

    # Scripts to execute once the node is setup
    node.addService(rspec.Execute(shell="sh", command="/local/repository/test.sh > /tmp/log_test.txt 2>&1"))
    node.addService(rspec.Execute(shell="sh", command="echo " + params.phystype + " > /tmp/hwtype.txt"))
    node.addService(rspec.Execute(shell="sh", command="echo " + name + " > /tmp/name.txt"))
    node.addService(rspec.Execute(shell="sh", command="echo " + worker_count + " > /tmp/node_counts.txt"))
    node.addService(rspec.Execute(shell="sh", command="echo " + client_count + " >> /tmp/node_counts.txt"))
    node.addService(rspec.Execute(shell="sh", command="sudo /local/repository/setup.sh > /tmp/log_setup.txt 2>&1"))

# Print the RSpec to the enclosing page.
pc.printRequestRSpec(request)
