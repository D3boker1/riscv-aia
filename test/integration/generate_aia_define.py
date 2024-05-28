import re

class CAiaDefines:
    def __init__(self, 
                 domain_direct_value,
                 domain_msi_value,
                 user_aplic_mode,
                 aplic_nr_sources,
                 aplic_nr_harts,
                 aplic_nr_domains,
                 aplic_min_prio,
                 riscv_xlen,
                 imsic_nr_sources,
                 imsic_nr_harts,
                 imsic_nr_vs_files):
        self.domain_direct_value = domain_direct_value
        self.domain_msi_value = domain_msi_value
        self.user_aplic_mode = user_aplic_mode
        self.aplic_nr_sources = aplic_nr_sources
        self.aplic_nr_harts = aplic_nr_harts
        self.aplic_nr_domains = aplic_nr_domains
        self.aplic_min_prio = aplic_min_prio
        self.riscv_xlen = riscv_xlen
        self.imsic_nr_sources = imsic_nr_sources
        self.imsic_nr_harts = imsic_nr_harts
        self.imsic_nr_vs_files = imsic_nr_vs_files

def parse_aplic_mode(file_content):

    # Define the regex patterns for the User variables and the DOMAIN modes
    aplic_nr_sources_pattern = re.compile(r'\s*localparam\s+UserNrSources\s+=\s+(\w+);')
    aplic_nr_harts_pattern = re.compile(r'\s*localparam\s+UserNrHarts\s+=\s+(\w+);')
    aplic_nr_domains_pattern = re.compile(r'\s*localparam\s+UserNrDomains\s+=\s+(\w+);')
    aplic_min_prio_pattern = re.compile(r'\s*localparam\s+UserMinPrio\s+=\s+(\w+);')
    aplic_mode_pattern = re.compile(r'\s*localparam\s+UserAplicMode\s+=\s+(\w+);')
    domain_direct_pattern = re.compile(r'\s*localparam\s+DOMAIN_IN_DIRECT_MODE\s+=\s+(\d+);')
    domain_msi_pattern = re.compile(r'\s*localparam\s+DOMAIN_IN_MSI_MODE\s+=\s+(\d+);')
    
    riscv_xlen_pattern = re.compile(r'\s*localparam\s+UserXLEN\s+=\s+(\w+);')
    imsic_nr_sources_pattern = re.compile(r'\s*localparam\s+UserNrSourcesImsic\s+=\s+(\w+);')
    imsic_nr_harts_pattern = re.compile(r'\s*localparam\s+UserNrHartsImsic\s+=\s+(\w+);')
    imsic_nr_vs_files_pattern = re.compile(r'\s*localparam\s+UserNrVSIntpFiles\s+=\s+(\w+);')

    # Initialize variables
    domain_direct_value = None
    domain_msi_value = None
    user_aplic_mode = None
    aplic_nr_sources = None
    aplic_nr_harts = None
    aplic_nr_domains = None
    aplic_min_prio = None
    riscv_xlen = None
    imsic_nr_sources = None
    imsic_nr_harts = None
    imsic_nr_vs_files = None

    # Search the file content for the patterns
    for line in file_content:
        if domain_direct_value is None:
            match = domain_direct_pattern.match(line)
            if match:
                domain_direct_value = int(match.group(1))
        if domain_msi_value is None:
            match = domain_msi_pattern.match(line)
            if match:
                domain_msi_value = int(match.group(1))
        if user_aplic_mode is None:
            match = aplic_mode_pattern.match(line)
            if match:
                user_aplic_mode = match.group(1)
        if aplic_nr_sources is None:
            match = aplic_nr_sources_pattern.match(line)
            if match:
                aplic_nr_sources = match.group(1)
        if aplic_nr_harts is None:
            match = aplic_nr_harts_pattern.match(line)
            if match:
                aplic_nr_harts = match.group(1)
        if aplic_nr_domains is None:
            match = aplic_nr_domains_pattern.match(line)
            if match:
                aplic_nr_domains = match.group(1)
        if aplic_min_prio is None:
            match = aplic_min_prio_pattern.match(line)
            if match:
                aplic_min_prio = match.group(1)
        if riscv_xlen is None:
            match = riscv_xlen_pattern.match(line)
            if match:
                riscv_xlen = match.group(1)
        if imsic_nr_sources is None:
            match = imsic_nr_sources_pattern.match(line)
            if match:
                imsic_nr_sources = match.group(1)
        if imsic_nr_harts is None:
            match = imsic_nr_harts_pattern.match(line)
            if match:
                imsic_nr_harts = match.group(1)
        if imsic_nr_vs_files is None:
            match = imsic_nr_vs_files_pattern.match(line)
            if match:
                imsic_nr_vs_files = match.group(1)

    return CAiaDefines(domain_direct_value,
                       domain_msi_value,
                       user_aplic_mode,
                       aplic_nr_sources,
                       aplic_nr_harts,
                       aplic_nr_domains,
                       aplic_min_prio,
                       riscv_xlen,
                       imsic_nr_sources,
                       imsic_nr_harts,
                       imsic_nr_vs_files)

def determine_irqc_type(user_aplic_mode, domain_direct_value, domain_msi_value):
    if user_aplic_mode == 'DOMAIN_IN_DIRECT_MODE':
        return domain_direct_value
    elif user_aplic_mode == 'DOMAIN_IN_MSI_MODE':
        return domain_msi_value
    else:
        raise ValueError("Unknown UserAplicMode value")

def write_to_file (file_name, macro, write_mode, varible):
    with open(file_name, write_mode) as f:
        f.write(f"{macro} = {varible}\n")


def main():
    # Read the content of the file
    with open("../../rtl/ieaia_dev/package/aia_pkg.sv", 'r') as f:
        file_content = f.readlines()

    # Parse the UserAplicMode and domain values
    aia_variables = parse_aplic_mode(file_content)

    # Determine the IRQC_TYPE based on UserAplicMode
    irqc_type = determine_irqc_type(aia_variables.user_aplic_mode, aia_variables.domain_direct_value, aia_variables.domain_msi_value)

    # Write the IRQC_TYPE to aia_define.py
    write_to_file ('aia_define.py', "AIA_MODE", 'w', irqc_type)

    if (irqc_type == 0):
        type = "direct"
    elif (irqc_type == 1):
        type = "msi"
    write_to_file ('aia_define.mk', "AIA_MODE", 'w', type)

    write_to_file ('aia_define.py', "APLIC_NR_SRC", 'a', aia_variables.aplic_nr_sources)
    write_to_file ('aia_define.py', "APLIC_NR_HARTS", 'a', aia_variables.aplic_nr_harts)
    write_to_file ('aia_define.py', "APLIC_NR_DOMAINS", 'a', aia_variables.aplic_nr_domains)
    write_to_file ('aia_define.py', "APLIC_MIN_PRIO", 'a', aia_variables.aplic_min_prio)
    write_to_file ('aia_define.py', "RISCV_XLEN", 'a', aia_variables.riscv_xlen)
    write_to_file ('aia_define.py', "IMSIC_NR_SRC", 'a', aia_variables.imsic_nr_sources)
    write_to_file ('aia_define.py', "IMSIC_NR_HARTS", 'a', aia_variables.imsic_nr_harts)
    write_to_file ('aia_define.py', "IMSIC_NR_VS_FILES", 'a', aia_variables.imsic_nr_vs_files)

if __name__ == "__main__":
    main()

