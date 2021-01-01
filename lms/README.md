# Prepare 

```bash

sudo useradd -r -s /sbin/nologin lms
sudo groupadd lms
sudo usermod -a -G lms lms
sudo mkdir /opt/lms

sudo chown -R lms:lms /opt/lms
```