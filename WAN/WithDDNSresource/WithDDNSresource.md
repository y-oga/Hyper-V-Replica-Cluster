# Setup DDNS resource and NAT

1. Create a cluster following <a href="https://github.com/y-oga/Setup-Cluster-with-Hyper-V-Replica-and-RouterVM/blob/master/How_to_create_cluster.md">How_to_create_cluster.md</a>

2. Install NAT in both servers on **Server Manager**
    - Role: **Remote Access**
    - Feature: **Routing**

3. Set IP address of **internal-network**

    **internal-network** is Hyper-V virtual switch. This is created  during executing automation tool.
    - This IP address is used for a gateway of all VMs.

4. Enable NAT on both servers
    - Open **Routing and Remote Access**
    - Right-click server name and click **Configure and Enabling Routing and Remote Access**
    - Configuration
        - Check **Network address translation (NAT)**
    - NAT Internet Connection
        - Check **Use this public interface to connecto to the Internet:**
        - Selct the public interface
    - Network Selection
        - Select **vEthernet (internal-network)**
    - Name and Address Translation Services
        - Check **Enable basic name and address services**
    - Address Assignment Range
        - Click **Next**
    - Click **Finish**

5. Setup NAT on both servers
    - Open **Routing and Remote Access**
    - Right-click the public interface in NAT list and click **Properties**.
    - In **Services and Ports**, add NAT settings for each VMs.

6. Add DDNS resource to a cluster on **EXPRESSCLUSTER Cluster WebUI**
    
    Each failover group needs to 1 ddns resource.
    
    Resource Details
    - Common
        - Virtual Host Name: The name which you want to register to DNS server
        - IP address: The IP address of priamry server
        - DDNS Server: The IP address of DNS server
        - Delete the Registered IP Address: Check
    - Secondary server
        - Set Up Individually: Check
        - IP Address: The IP address of secondary server