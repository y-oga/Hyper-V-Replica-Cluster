# Create Hyper-V Replica cluster automatically

## About this tool

This tool enables an user to create Hyper-V Replica cluster automatically.
Application VM is replicated between 2 host servers by Hyper-V Replica.
EXPRESSCLUSTER moves Application VM by controlling Hyper-V Replica when failover occurs.

You can create a cluster both in LAN and in WAN.

- LAN
  - Production site and DR site belong to the same network.

  ```
  (LAN)
  |
  |      +--------------------------------+
  |      | Windows Server 2012R2 or later |
  |      |     EXPRESSCLUSTER             |
  |      |     Hyper-V Replica            |
  +------+   IP: 192.168.0.1/24           |
  |      | +----------------------------+ |
  |      | | Application VM             | |
  |      | | IP: 192.168.0.10/24        | |
  |      | +----------------------------+ |
  |      +--------------------------------+
  |
  |
  |      +--------------------------------+
  |      | Windows Server 2012R2 or later |
  |      |     EXPRESSCLUSTER             |
  |------+     Hyper-V Replica            |
  |      |   IP: 192.168.0.2/24           |
  |      +--------------------------------+
  |
  ```

<br/>

- WAN
  - Production site and DR site belong to the different networks.
  - You can have 2 type of solutions to replicate a VM with a same IP address.
    - EXPRESSCLUSTER DDNS resource

      DNS server is required.
      Both host servers need to join Windows domain.

      Active server sends DNS query to DNS server after failover. Client machine can access Application VM with the same hostname through failover and failback.

      The packet from externel to Application VM is routed via NAT in a host server. 

      After setting a cluster following this document, please follow <a href="https://github.com/y-oga/Setup-Cluster-with-Hyper-V-Replica-and-RouterVM/blob/master/WAN/WithDDNSresource/WithDDNSresource.md">WithDDNSresource.md</a>

      ```
      (Internet)
      |               Production Site
      |      +-------------------------------------+
      |      | Windows Server 2012R2 or later      |
      |      |     EXPRESSCLUSTER                  |
      |      |     Hyper-V Replica                 |
      |      |     Routing and Remote Access (NAT) |
      +------+   IP: 192.168.1.1/24                |
      |      | +----------------------------+      |
      |      | | Application VM             |      |
      |      | | IP: 192.168.100.10/24      |      |
      |      | +----------------------------+      |
      |      +-------------------------------------+
      |
      ~
      ~
      |               DR Site
      |      +-------------------------------------+
      |      | Windows Server 2012R2 or later      |
      |      |     EXPRESSCLUSTER                  |
      +------+     Hyper-V Replica                 |
      |      |     Routing and Remote Access (NAT) |
      |      |   IP: 192.168.2.2/24                |
      |      +-------------------------------------+
      |
      ~
      ~
      |      +------------+
      +------+ DNS Server |
      |      +------------+
      |
      ```

    - Router VM
      
      Router VM is required.
      If you want to use this solution, please contact with Ogata to get Router VM.

      Router VM sends OSPF information to all network routers in the same network after failover.

      All network routers need to enable OSPF function.

      ```
      (Internet)
      |               Production Site
      |      +-------------------------------------+
      |      | Windows Server 2012R2 or later      |
      |      |     EXPRESSCLUSTER                  |
      |      |     Hyper-V Replica                 |
      |      |     Routing and Remote Access (NAT) |
      +------+   IP: 192.168.1.1/24                |
      |      | +-----------------------+           |
      |      | | Router VM             |           |
      |      | | IP: 192.168.1.10/24   |           |
      |      | | IP: 192.168.100.1/24  |           |
      |      | +-----------+-----------+           |
      |      |             |                       |
      |      | +-----------+----------------+      |
      |      | | Application VM             |      |
      |      | | IP: 192.168.100.10/24      |      |
      |      | +----------------------------+      |
      |      +-------------------------------------+
      |
      ~
      ~
      |               DR Site
      |      +-------------------------------------+
      |      | Windows Server 2012R2 or later      |
      |      |     EXPRESSCLUSTER                  |
      |      |     Hyper-V Replica                 |
      |      |     Routing and Remote Access (NAT) |
      +------+   IP: 192.168.2.2/24                |
      |      | +-----------------------+           |
      |      | | Router VM             |           |
      |      | | IP: 192.168.2.10/24   |           |
      |      | | IP: 192.168.100.1/24  |           |
      |      | +-----------+-----------+           |
      |      |             |                       |
      |      | +-----------+----------------+      |
      |      | | Application VM             |      |
      |      | | IP: 192.168.100.10/24      |      |
      |      | +----------------------------+      |
      |      +-------------------------------------+
      |
      ```

<br/>

## System Requirement

- 2 Windows Server
  - OS: Windows Server 2012 R2 or later
  - 2 servers are IP reachable each other

## How to use Automation-tool

### Premise

- OS has already been installed on **both servers**.
- Windows Administrator password are the same between both servers.
- IP address has already been set in **both servers**.
  - 2 servers are IP reachable each other.
- Copy the Hyper-V VM image that you want to protect using EXPRESSCLUSTER to somewhere in **primary server**.
  - The VM has one network adapter.
  - Before you export the VM image, please detach a virtual switch from a network adapter of the VM.
- Before copying **AutoScripts** to both servers, edit **global_config.bat** in `Auto\config`
  - The way to edit the config file is described below.
- Copy **AutoScripts** to somewhere in **both servers**.
- If you use Router VM, copy **RouterVM** image to same path in **both servers**.
- If both host servers do NOT join Windows domain, you need to create certificates in advance.
  - The way to create certificates is described below.

### How to edit global_config.bat

global_config.bat is in `Auto\config`
- ECX_PATH
  - Path of EXPRESSCLUSTER
  - The path where includes **menu.exe**
- PRIMARY_HOSTNAME
  - Hostname of primary server
- PRIMARY_IP_ADDRESS
  - IP address of primary server
- SECONDARY_HOSTNAME
  - Hostname of secondary server
- SECONDARY_IP_ADDRESS
  - IP address of secondary server
- DOMAIN
  - Domain to which 2 host servers belong
  - If 2 host servers do NOT belong to Windows domain, please input *hyperv.local*.
- CERT_FILE_PASSWORD
  - Password of certificates for Hyper-V Replica
  - Please set any value
- APP_VM_NUM
  - The number of Application VMs
- APP_VM_PATH
  - Path of VM that you want to protect using EXPRESSCLUSTER
    - **Virtual Machines** folder
- APP_VM_ID
  - ID of VM that you want to protect using EXPRESSCLUSTER
  - VM ID is described in vmcx file name or xml file
    - \<VM ID\>.vmcx (Windows Server 2016 or later)
    - \<VM ID\>.XML (Windows Server 2012)
- APP_VM_NAME
  - Name of VM that you want to protect using EXPRESSCLUSTER
- LCNS_PATH
  - Path of EXPRESSCLUSTER license file.
- ECX_OR_CLP
  - If you use EXPRESSCLUSTER, set ECX
  - If you use CLUSTERPRO, set CLP
- ADMIN_PASS
  - Windows Administrator Password encrypted by EXPRESSCLUSTER WebUI
  - You can get encrypted password by following the below steps
    - Open WebUI
    - Go to **Config mode**
    - Open **Cluster Properties**
    - Go to **Account** Tab
    - Click **Add**
    - Input **Administrator** as **User Name**
    - Input **Password**
    - Export the configuration file
    - Encrypted password is described in **\<password\>** in **clp.conf**

If you use Router VM, please edit the below parameters

- ROUTER_VM_PATH
  - Path of Router VM
    - **Virtual Machines** folder
- ROUTER_VM_ID
  - ID of Router VM
  - VM ID is described in vmcx file name
    - \<VM ID\>.vmcx (Windows Server 2016 or later)
    - \<VM ID\>.XML (Windows Server 2012)
- VM_SWITCH_PUB_NAME
  - Do not need to edit
- VM_SWITCH_APP_NAME
  - Do not need to edit
- PRIMARY_IP_ADDRESS_TO_PUB
  - IP address of Router VM which connects to host server
- PRIMARY_NETWORK_OF_PUB
  - Network address of Router VM which connects to host server
- PRIMARY_SUBNET_PUB
  - Subnet mask of Router VM which connects to host server
- PRIMARY_IP_ADDRESS_TO_APP
  - IP address of Router VM which connects to protected VM
- PRIMARY_NETWORK_OF_APP
  - Network address of Router VM which connects to protected VM
- PRIMARY_SUBNET_APP
  - Subnet mask of Router VM which connects to protected VM
- PRIMARY_IP_ADDRESS_TO_DNS
  - IP address of DNS
- PRIMARY_IP_ADDRESS_TO_GATEWAY
  - IP address of gateway
- SECONDARY_IP_ADDRESS_TO_PUB
  - IP address of Router VM which connects to host server
- SECONDARY_NETWORK_OF_PUB
  - Network address of Router VM which connects to host server
- SECONDARY_SUBNET_PUB
  - Subnet mask of Router VM which connects to host server
- SECONDARY_IP_ADDRESS_TO_APP
  - IP address of Router VM which connects to protected VM
- SECONDARY_NETWORK_OF_APP
  - Network address of Router VM which connects to protected VM
- SECONDARY_SUBNET_APP
  - Subnet mask of Router VM which connects to protected VM
- SECONDARY_IP_ADDRESS_TO_DNS
  - IP address of DNS
- SECONDARY_IP_ADDRESS_TO_GATEWAY
  - IP address of gateway

### How to create certificates for Hyper-V Replica

If host servers are Windows Server 2012 R2, in advance, you need to create the certificates on Windows 10 or Windows Server 2016 or Windows Server 2019.

If host servers are Windows Server 2016 or later, you don't need to create certificates in advance.

1. Edit **config.bat** in **makecert**
  - Each values must be identical with each values in **glocal_config.bat**
2. Execute **makecert.bat** in **makecert**
  - 3 certificates are created in **makecert**
    - **CertRecTestRoot.cer**
    - **\<primary hostname\>.hyperv.local.pfx** 
    - **\<secondary hostname\>.hyperv.local.pfx** 
3. Copy **CertRecTestRoot.cer** and **\<primary hostname\>.hyperv.local.pfx** to `AutoScripts\tool2\setup_Hyper-VReplica_Primary` folder on primary server
4. Copy **CertRecTestRoot.cer** and **\<secondary hostname\>.hyperv.local.pfx** to `AutoScripts\tool2\setup_Hyper-VReplica_Secondary` folder on secondary server

### Execute Automation-tool (Windows Server 2012 R2)

1. Execute **tool1** on both servers
  - **install_softwares_Primary.bat** in `AutoScripts\tool1\install_softwares_Primary` on primary server
  - **install_softwares_Secondary.bat** in `AutoScripts\tool1\install_softwares_Secondary` on secondary server
2. Wait for both servers to reboot
3. Execute **tool2** on both servers
  - **setup_Hyper-VReplica_Primary.bat** in `AutoScripts\tool2\setup_Hyper-VReplica_Primary` on primary server
  - **setup_Hyper-VReplica_Secondary.bat** in `AutoScripts\tool2\setup_Hyper-VReplica_Secondary` on secondary server
4. Enable Hyper-V Replica on both servers
  - If both servers belong to Windows domain
    - Open **Hyper-V Manager**
    - Right-click server name
    - Click **Hyper-V Settings**
    - Click **Replication Configuration**
    - Check **Enable this computer as a Replica server**
    - Check **Use Kerberos (HTTP):**
    - Check **Allow replication from any authenticated server**
    - Click **Apply**
    - Click **OK** in Settings dialog
    - Click **OK**
  - If both servers do NOT belong to Windows domain
    - Open **Hyper-V Manager**
    - Right-click server name
    - Click **Hyper-V Settings**
    - Click **Replication Configuration**
    - Check **Enable this computer as a Replica server**
    - Check **Use certificate-based Authentication (HTTPS):**
    - Click **Select Certificate**
    - Click **OK** in Select certificate dialog
    - Check **Allow replication from any authenticated server**
    - Click **Apply**
    - Click **OK** in Settings dialog
    - Click **OK**
5. Confirm Firewall setting on both servers
6. Execute **tool3** on primary server
  - **start_VMreplication.bat** in `AutoScripts\tool3\start_VMreplication_Primary`
7. Execute **tool4**
  - Without Router VM
    - **setup_network_Secondary.bat** in `AutoScripts\tool4\setup_network_Secondary` on secondary server
8. Execute **tool5** on primary server
  - **setup_ecx_Primary.bat** in `AutoScripts\tool5\setup_ecx_Primary`
  - After this step, failover group will start, but Application VMs will not start. They will start after next step.
9. Execute **tool6** on secondary server
  - **setup_ecx_Secondary.bat** in `AutoScripts\tool6\setup_ecx_Secondary`

### Execute Automation-tool (Windows Server 2016 or later)

1. Execute **tool1** on both servers
  - **install_softwares_Primary.bat** in `AutoScripts\tool1\install_softwares_Primary` on primary server
  - **install_softwares_Secondary.bat** in `AutoScripts\tool1\install_softwares_Secondary` on secondary server
2. Wait for both servers to reboot
3. Copy two certificate files to `AutoScripts\tool2\setup_Hyper-VReplica_Secondary` on secondary server
  - **CertRecTestRoot.cer** and **\<secondary hostname\>.hyperv.local.pfx** is generated in `AutoScripts\tool1\install_softwares_Primary` on primary server
4. Execute **tool2** on both servers
  - **setup_Hyper-VReplica_Primary.bat** in `AutoScripts\tool2\setup_Hyper-VReplica_Primary` on primary server
  - **setup_Hyper-VReplica_Secondary.bat** in `AutoScripts\tool2\setup_Hyper-VReplica_Secondary` on secondary server
5. Enable Hyper-V Replica on both servers
  - Open **Hyper-V Manager**
  - Right-click server name
  - Click **Hyper-V Settings**
  - Click **Replication Configuration**
  - Check **Enable this computer as a Replica server**
  - Check **Use certificate-based Authentication (HTTPS):**
  - Click **Select Certificate**
  - Click **OK** in Select certificate dialog
  - Check **Allow replication from any authenticated server**
  - Click **Apply**
  - Click **OK** in Settings dialog
  - Click **OK**
6. Execute **tool3** on primary server
  - **start_VMreplication.bat** in `AutoScripts\tool3\start_VMreplication_Primary`
7. Execute **tool4**
  - With Router VM
    - **setup_routerVM_Primary.bat** in `AutoScripts\tool4\setup_routerVM_Primary` on primary server
    - **setup_routerVM_Secondary.bat** in `AutoScripts\tool4\setup_routerVM_Secondary` on secondary server
  - Without Router VM
    - **setup_network_Secondary.bat** in `AutoScripts\tool4\setup_network_Secondary` on secondary server
8. Execute **tool5** on primary server
  - **setup_ecx.bat** in `AutoScripts\tool5\setup_ecx_Primary`
  - Please press just Enter when creating ssh key
9. Execute **tool6** on secondary server
  - **reboot_webmanager.bat** in `AutoScripts\tool6\reboot_webmanager_Secondary`

## Behavior after server's failure

When the target VM is running on primary server,

- Primary server's shutdown or power failure
  - The target VM starts on secondary server
- Secondary server's shutdown or power failure
  - The target VM keeps running on primary server

When the target VM is running on secondary server, vice versa.

## Behavior after split brain

When network between primary server and secondary server disconnects, the target VM starts on both servers. (Dual activation)

After the network recovers, secondary server shuts down as NP resolution of EXPRESSCLUSTER.

The target VM keeps running on primary server through before NP resolution and after NP resolution.