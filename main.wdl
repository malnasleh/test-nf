version 1.0

workflow print_filename {
  input {
    String filename
  }

  call print_to_console {
    input:
      filename = filename
      docker = "ubuntu:latest"
  }

  output {
    String result = print_to_console.output
  }
}

task print_to_console {
  input {
    String filename
    String docker
  }

  command {
    echo "The filename is: ${filename}"
  }

  output {
    String output = "The filename is: ${filename}"
  }
}