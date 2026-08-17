function program_fpga
    if test -f ./tools/program_fpga.sh
        ./tools/program_fpga.sh
    else
        echo "Error: ./tools/program_fpga.sh not found. Make sure you are in the project root."
    end
end
