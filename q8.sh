#!/bin/bash

########################
# include the magic
########################
. bin/demo-magic.sh

# hide the evidence
clear

# Pre-requisites: cosign, docker, jq, crane

# Remove all signatures from an image 
# cosign clean

# QUESTION 8

#p "Q8. Avec Cosign, quand je signe une image, la signature est ... ?"

# generate key pair with cosign
p 'Génération de la clé privé et de la clé publique'
pe 'cosign generate-key-pair'

#p 'docker login -u snowcamp 79352h8v.c1.de1.container-registry.ovh.net'
#docker login -u snowcamp -p SnowCamp2025 79352h8v.c1.de1.container-registry.ovh.net

# Récupération du digest de l'image
# Il est conseillé de signer une image a partir de son digest et non de son tag.
pe "docker inspect 79352h8v.c1.de1.container-registry.ovh.net/public/gophers-api | jq -r '.[0].RepoDigests[0]'"
IMG_DIGEST=$(docker inspect 79352h8v.c1.de1.container-registry.ovh.net/public/gophers-api | jq -r '.[0].RepoDigests[0]')

# sign the OCI artifact and push to the Managed Private Registry/Harbor instance
# and store the transparency log (metadata) in the public Rekor server at https://rekor.sigstore.dev/ (to verify the signature afterward)
#pe 'cosign sign --key cosign.key 79352h8v.c1.de1.container-registry.ovh.net/public/gophers-api'
pe "cosign sign --key cosign.key $IMG_DIGEST"

# Verify the image is signed with cosign
pe 'cosign verify 79352h8v.c1.de1.container-registry.ovh.net/public/gophers-api --key cosign.pub -o text | jq'

p 'Vérification sur le OVHcloud private registry: 79352h8v.c1.de1.container-registry.ovh.net'
# Access to the registry, green check mark
# Click on the > icon that displays the associated cosign signature information
# Cosign créé une signature qui est attachée a l'image sous forme de metadata externe (comme un nouveau tag specifique), mais ne modifie pas l'image orignale ni ne créé une copie

# Le tag a la forme sha256:<digest>.sig pour s'assurer qu'il correspond a l'image d'origine
# La signature est un "accessory" d'une image et elle est associée a un nouveau tag
pe "cosign triangulate 79352h8v.c1.de1.container-registry.ovh.net/public/gophers-api"

# Inspection du manifest de ce tag special
pe "crane manifest $(cosign triangulate 79352h8v.c1.de1.container-registry.ovh.net/public/gophers-api) | jq ."


p "Tips: On peut meme ajouter une annotation/information a notre signature"
pe "cosign sign -a conf=snowcamp --key cosign.key $IMG_DIGEST"

# Verify the image is signed with cosign
pe 'cosign verify 79352h8v.c1.de1.container-registry.ovh.net/public/gophers-api --key cosign.pub -o text | jq'


# Montrer que l'image n'est pas modifiée avant/apres ?
# docker pull de la signature pour voir quelle tronche ça a ?

# Verif sur le docker hub? ou montrer uniquement sur Harbor suffit ?
#p 'Vérification sur le Docker Hub: https://hub.docker.com/r/scraly/gophers-api/tags'

p "Fini !"



# Image reference 79352h8v.c1.de1.container-registry.ovh.net/public/gophers-api uses a tag, not a digest, to identify the image to sign.
#    This can lead you to sign a different image than the intended one. Please use a
#    digest (example.com/ubuntu@sha256:abc123...) rather than tag
#    (example.com/ubuntu:latest) for the input to cosign. The ability to refer to
#    images by tag will be removed in a future release.
