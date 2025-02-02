#!/bin/sh
set -e

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'Crossplane Destruction'

#########################
# Control Plane Cluster #
#########################

	kind delete cluster
