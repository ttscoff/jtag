---
layout: post
title: Custom URLs for your Synology with Namecheap
categories:
- Code
tags:
- synology
comments: true
post_class: code
keywords:
- synology
- dsm
- namecheap
- ddns
- dynamic dns
date: 2021-08-26 09:19
slug: custom-urls-for-your-synology-with-namecheap
---
The [Synology](https://www.synology.com/en-global) DSM has a handy built-in updater for dynamic DNS (DDNS). It makes a lot of sense, given the Synology is always on and connected to the internet, keeping a custom domain pointed to the right IP at all times.

Most people who followed this headline already know these definitions, but just to recap: dynamic DNS allows a fully qualified domain name like "example.com" to point to an IP address that changes regularly, as most home ISPs do. Unless you're paying for a static IP, your IP is changing now and then, defeating any custom domains you point to it.

Synology's DDNS integration comes with presets for quite a few services, but most of the free ones don't allow you to use custom domain names, just subdomains of domains like "synology.me" or "zapto.org". I wanted to use something short and personalized (because I'm lazy and vain, I guess).

I already had some unused domains registered with Namecheap, which offers DDNS for your domains, but Synology didn't have a preset for it. In a lot of cases you can use the DSM to create a custom DDNS, using a URL with `__PLACEHOLDERS__` in it. Namecheap doesn't offer a URL you can curl, though, and using `dynamicdns.park-your-domain.com` doesn't work with that (I'm not sure why). The good news is that it's pretty easy to add your own Namecheap service provider to your Synology.

I found a few existing solutions for this but each of them had some failing. This solution is what I distilled from multiple sources, simplified, and currently have working.

1. First, register the domain you want to use with [Namecheap](https://www.namecheap.com/) and go to the Advanced DNS configuration for the domain. Ensure that there's a an A record for the "@" wildcard.

	{% img aligncenter /uploads/2021/08/NamecheapAdvancedDNS.png 1168 240 "Namecheap Advanced DNS" "Namecheap Advanced DNS" %}

	If you want to use a subdomain as your dynamic host (e.g. "home.example.com"), add a record for it by clicking "Add New Record", selecting A Record, and entering the subdomain (just "home" in the previous example). The IP address here doesn't matter, the script we'll set up will be updating that.

2. Scroll down to Dynamic DNS, toggle the switch to enable it, and note/copy the password it shows you, we'll use that in step 6.

	{% img aligncenter /uploads/2021/08/NamecheapDynamicDNS.png 888 146 "Namecheap Dynamic DNS" %}

3. For this next part, you'll need SSH access to your Synology, which you can enable with **Control Panel->Terminal & SNMP**.

	> As an aside, I highly recommend changing the default SSH port, [setting up keys](https://silica.io/using-ssh-key-authentification-on-a-synology-nas-for-remote-rsync-backups/), and [disabling password login](https://linuxhandbook.com/ssh-disable-password-authentication/). Also set your **Control Panel->Security** setting to the highest level. Especially once you have a public domain associated with your IP, you'll get your ports scanned frequently, and there will be regular brute force login attempts. 
	{:.tip}

4. Now, add a little script that will handle pinging an update URL with your credentials and IP. Save [this script](https://gist.github.com/fab7137c71d951d36b166622a4d5800d) to `/usr/local/bin/namecheap_ddns.sh` on your Synology:

	```bash
	#!/bin/bash

	## Namecheap DDNS updater for Synology
	## Brett Terpstra <https://brettterpstra.com>

	PASSWORD="$2"
	DOMAIN="$3"
	IP="$4"

	PARTS=$(echo $DOMAIN | awk 'BEGIN{FS="."} {print NF?NF-1:0}')
	# If $DOMAIN has two parts (domain + tld), use wildcard for host
	if [[ $PARTS == 1 ]]; then
	    HOST='@'
	    DOMAIN=$DOMAIN
	# If $DOMAIN has a subdomain, separate for HOST and DOMAIN variables
	elif [[ $PARTS == 2 ]]; then
	    HOST=${DOMAIN%%.*}
	    DOMAIN=${DOMAIN#*.}
	fi

	RES=$(curl -s "https://dynamicdns.park-your-domain.com/update?host=$HOST&domain=$DOMAIN&password=$PASSWORD&ip=$IP")
	ERR=$(echo $RES | sed -n "s/.*<ErrCount>\(.*\)<\/ErrCount>.*/\1/p")

	if [[ $ERR -gt 0 ]]; then
	    echo "badauth"
	else
	    echo "good"
	fi
	```

	Make it executable with `chmod a+x /usr/local/bin/namecheap_ddns.sh`. 

5. Next, we need to add the provider to the DSM configuration. You'll need to be root to do this, so run `sudo -i` and enter your admin account's password. Now edit the file at `/etc.defaults/ddns_provider.conf`. I have Vim installed on my Synology, but I can't remember if it's included by default or I added it. Use whatever you have handy, or use `cat` redirection to do it (copy and paste the whole block below at once):

		cat >> /etc.defaults/ddns_provider.conf << 'EOF'
		[Namecheap]
		        modulepath=/usr/local/bin/namecheap.sh
		        queryurl=https://namecheap.com
		        website=https://namecheap.com
		EOF
	
6. Go back to your Synology DSM and open **Control Panel->External Access->DDNS**. Click Add and you should see Namecheap in the Service Provider dropdown. Select it and enter your custom domain (including subdomain if you set that up) in the **Hostname** field. Username isn't needed in our script, just paste your password from step 2 in the **Password/Key** field. Click "Automatic Setup" next to **External Address** to enter your current public IP.

	{% img aligncenter /uploads/2021/08/SynologyEditDNS.png 768 528 "Synology Add DDNS" %}

	Click the **Test Connection** button to see if everything is working. Click OK to save.

Assuming you see *Normal* under the **Status** column, you're now updating your custom domain with your public IP. It may take a bit for it to propagate initally, but once it does, you can access Synology DSM, Synology Drive, Filestation, and all of your packages using your custom domain and the appropriate ports. If you head to **Control Panel->Security->Certificate**, there's even a wizard for adding a Let's Encrypt SSL certificate for your new domain, allowing you to use `https` connections for everything.

Hope that's useful to some Synology users out there, it was definitely a fun little hack for me.
