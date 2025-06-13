
#!/bin/bash

if [ ! -d "/mnt/disks/persist" ]; then
  # Create the directory
  sudo mkdir -p /mnt/disks/persist
  
  # Set permissions to 777
  sudo chmod 777 -R /mnt/disks/persist
  
  echo "Directory /mnt/disks/persist created and permissions set to 777."
else
  echo "Directory /mnt/disks/persist already exists."
fi

if [ -d "$HOME/miniconda3" ]; then
  CONDA="$HOME/miniconda3"
elif [ -d "/opt/conda" ]; then
  CONDA="/opt/conda"
else
  echo "Error: Conda installation not found." >&2
  exit 1
fi

# $CONDA/bin/conda create -n vllm_spanner python=3.12 -y
