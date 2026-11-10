# Justification

> TODO: replace this line and the placeholders below with your own text.
> About 400 words in total. Your own words — this is the part where you show
> you understand what you built.

## Choice 1  SSH key pair 

> TODO: what did you decide, which alternative did you reject, and why?
I decided to store the public keep on the server and to keep the private key exclusevely on my host because this direction is crucial for security. Asymmetric cryptographiy relies on the secrecy of the privat_key. this avoids the exposure of the client's master credentials.So by keeping it local and only sharing the public key, the server can cryptographically challenge the client to ptove ownership of the private key without transmitting the secret itself 

## Choice 2 Service account blocking strategy ('svc-flint')

> TODO 
for the service account 'svc-flint', I rely primarily on setting its shell to '/usr/sbin/nologin' at the OS level (configured during 'useradd) combind with ssh hardenning rules(no ssh key authorized and password authentication disabled)

because using /usr/sbin/nologin provides a robust defense-in-depth mechanism. It prevents interactive shell access eacross all possible vectors-wheter via SSH,local console, or  'su' to make sure sure that even if SSH configuration or dropin files are ever modified or misconfigured in the future, the service account can nerver obtain an interactieve sessie

## Choice 3 Sudoers least privliege implementation
I implemented the principle of least privilige for tasks by separating permissions using dedicated files inside '/etc/sudoers.d/'
Specifaccy , 'fien' is granted full administrative privileges('ALL=(ALL:ALL)) for complete sys mag,while 'bram' is restricted solely to specific binaries required for operational maintenance ("/usr/sbin/service' and /usr/bin/apt-get update'). this prevnts broad root access for standard operators and limists  the blast raduis of potentioal misconfiguration
> TODO

## AI statement

AI tools are allowed for this assignment. State here what you used.

- **Which tools** (if none, write "none"):
- **What you asked them**:
- **What came back**:
- **What you changed about it, and why**:

A submission without this section is incomplete. Being honest here costs you
nothing; the marks are for understanding what you handed in, not for having
worked unaided.
