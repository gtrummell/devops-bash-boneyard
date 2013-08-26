#!/bin/bash
ssh -i $HOME/.ssh/infra_whisper_prod.key ubuntu@$1 $2
