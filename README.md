# SSHouting [WORK IN PROGRESS]
Automates the setup of ssh &amp; able to update the keys frequently


## Usage
```bash
./sshouting.sh --install \
  --Username admin@<distribution-server> \
  --ssh-key ~/.ssh/id_rsa \
  --allow-users /etc/ssh/allowed_users.txt
```
