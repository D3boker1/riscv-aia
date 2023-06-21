from os import setpgid
from readline import set_pre_input_hook
import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import random

# The test functions need to use the decorator @cocotb.test()
# Usage: await cocotb.start(generate_clock(dut))  # run the clock "in the background"
# if you want to wait a specific time: await Timer(5, units="ns")  # wait a bit

NR_SRC                  = 32
NR_BITS_SRC             = NR_SRC if (NR_SRC > 31) else 32
NR_REG                  = NR_SRC//32
NR_IDC                  = 1

IDC_PER_BIT             = 1
SRC_PER_BIT             = 1
SRCCFG_W                = 11

TOPI_W                  = 26
TOPI_INTP_ID            = 16
TOPI_INTP_PRIO          = 0

APLIC_M_BASE            = 0xc000000
APLIC_S_BASE            = 0xd000000

# Sourcecfg base macro
SOURCECFG_M_BASE        = APLIC_M_BASE + 0x0004
SOURCECFG_S_BASE        = APLIC_S_BASE + 0x0004
SOURCECFG_OFF           = 0x0004

# Target base macros
TARGET_M_BASE           = APLIC_M_BASE + 0x3004
TARGET_S_BASE           = APLIC_S_BASE + 0x3004
TARGET_OFF              = 0x0004

SETIPNUM_M_BASE         = APLIC_M_BASE + 0x1CDC
SETIPNUM_S_BASE         = APLIC_S_BASE + 0x1CDC
CLRIPNUM_M_BASE         = APLIC_M_BASE + 0x1DDC
CLRIPNUM_S_BASE         = APLIC_S_BASE + 0x1DDC
SETIP_M_BASE            = APLIC_M_BASE + 0x1C00
SETIP_S_BASE            = APLIC_S_BASE + 0x1C00
INCLRIP_M_BASE          = APLIC_M_BASE + 0x1D00
INCLRIP_S_BASE          = APLIC_S_BASE + 0x1D00

# IDC macros
IDELIVERY_M_BASE        = APLIC_M_BASE + 0x4000 + 0x00
IDELIVERY_S_BASE        = APLIC_S_BASE + 0x4000 + 0x00
IFORCE_M_BASE           = APLIC_M_BASE + 0x4000 + 0x04
IFORCE_S_BASE           = APLIC_S_BASE + 0x4000 + 0x04
ITHRESHOLD_M_BASE       = APLIC_M_BASE + 0x4000 + 0x08
ITHRESHOLD_S_BASE       = APLIC_S_BASE + 0x4000 + 0x08
CLAIMI_M_BASE           = APLIC_M_BASE + 0x4000 + 0x1C
CLAIMI_S_BASE           = APLIC_S_BASE + 0x4000 + 0x1C


# interrupt sources macros
# Just to make the code more readable
class CSources:
    SRC = list(range(0, NR_SRC))

intp = CSources()

class CInputs:
    reg_intf_req_a32_d32_addr = 0
    reg_intf_req_a32_d32_write = 0
    reg_intf_req_a32_d32_wdata = 0
    reg_intf_req_a32_d32_wstrb = 0
    reg_intf_req_a32_d32_valid = 0
    i_rectified_src            = 0

class COutputs:
    reg_intf_resp_d32_rdata = 0
    reg_intf_resp_d32_error = 0
    reg_intf_resp_d32_ready = 0

input                   = CInputs()
outputs                 = COutputs()


def set_reg(reg, hexa, reg_width, reg_num):
    reg     = (hexa << reg_width*reg_num)
    return reg

def set_or_reg(reg, hexa, reg_width, reg_num):
    reg     = reg | (hexa << reg_width*reg_num)
    return reg

def read_bit_from_reg(reg, bit_num):
    aux     = int(reg)
    aux     = (aux >> bit_num) & 1
    return aux

def axi_write_reg(dut, addr, data):
    input.reg_intf_req_a32_d32_addr = addr
    input.reg_intf_req_a32_d32_wdata = data
    input.reg_intf_req_a32_d32_write = 1 
    input.reg_intf_req_a32_d32_wstrb = 0 
    input.reg_intf_req_a32_d32_valid = 1

    dut.reg_intf_req_a32_d32_addr.value = input.reg_intf_req_a32_d32_addr
    dut.reg_intf_req_a32_d32_wdata.value = input.reg_intf_req_a32_d32_wdata
    dut.reg_intf_req_a32_d32_write.value = input.reg_intf_req_a32_d32_write
    dut.reg_intf_req_a32_d32_wstrb.value = input.reg_intf_req_a32_d32_wstrb
    dut.reg_intf_req_a32_d32_valid.value = input.reg_intf_req_a32_d32_valid 

def axi_read_reg(dut, addr):
    input.reg_intf_req_a32_d32_addr = addr
    input.reg_intf_req_a32_d32_valid = 1
    input.reg_intf_req_a32_d32_write = 0

    dut.reg_intf_req_a32_d32_addr.value = input.reg_intf_req_a32_d32_addr
    dut.reg_intf_req_a32_d32_write.value = input.reg_intf_req_a32_d32_write
    dut.reg_intf_req_a32_d32_valid.value = input.reg_intf_req_a32_d32_valid 

    outputs.reg_intf_resp_d32_rdata = dut.reg_intf_resp_d32_rdata.value
    return outputs.reg_intf_resp_d32_rdata 
    
async def test_domaincfg(dut):
    # Disable domain
    axi_write_reg(dut, APLIC_M_BASE, 1)
    await Timer(3, units="ns")

async def test_every_register(dut):
    # Make source 14 active in M domain, edge-sensitive rising edge
    axi_write_reg(dut, SOURCECFG_M_BASE+(SOURCECFG_OFF * 13), 4)
    await Timer(4, units="ns")
    # Make source 23 active in S domain, edge-sensitive rising edge
    axi_write_reg(dut, SOURCECFG_S_BASE+(SOURCECFG_OFF * 22), 4)
    await Timer(4, units="ns")

    # Write value 14 for setipnum in M domain
    axi_write_reg(dut, SETIPNUM_M_BASE, 14)
    await Timer(4, units="ns")
    # Write value 23 for setipnum in S domain
    axi_write_reg(dut, SETIPNUM_S_BASE, 23)
    await Timer(4, units="ns")
    # Write value 7 for setipnum in M domain. 
    # Is not expected to change since it is not active in this domain
    axi_write_reg(dut, SETIPNUM_M_BASE, 7)
    await Timer(4, units="ns")

    # Write value 14 for clripnum in M domain
    axi_write_reg(dut, CLRIPNUM_M_BASE, 14)
    await Timer(4, units="ns")
    # Write value 23 for clripnum in S domain
    axi_write_reg(dut, CLRIPNUM_S_BASE, 23)
    await Timer(4, units="ns")
    # Write value 7 for clripnum in M domain. 
    # Is not expected to change since it is not active in this domain
    axi_write_reg(dut, CLRIPNUM_M_BASE, 7)
    await Timer(4, units="ns")

    # write 0x4000 to setip (set interrupt 14) domain M
    axi_write_reg(dut, SETIP_M_BASE, 0x4000)
    await Timer(4, units="ns")
    # write 0x800000 to setip (set interrupt 23) domain S
    axi_write_reg(dut, SETIP_S_BASE, 0x800000)
    await Timer(4, units="ns")

    # write 0x4000 to inclrip (clear interrupt 14) domain M
    axi_write_reg(dut, INCLRIP_M_BASE, 0x4000)
    await Timer(4, units="ns")
    # write 0x800000 to inclrip (clear interrupt 23) domain S
    axi_write_reg(dut, INCLRIP_S_BASE, 0x800000)
    await Timer(4, units="ns")

    # rectified value that goes into the register controller.
    # Is expected to see intp 23 in in_clrip from M domain and 
    # interrupt 14 in in_clrip from S domain
    dut.i_rectified_src.value = 0x804000

    # Make TARGET 14 in M domain, hart = 3, prio =  2
    axi_write_reg(dut, TARGET_M_BASE+(TARGET_OFF * 13), (3 << 18) | (2 << 0))
    await Timer(4, units="ns")
    # Make TARGET 23 in S domain, hart = 2, prio = 1
    axi_write_reg(dut, TARGET_S_BASE+(TARGET_OFF * 22), (2 << 18) | (1 << 0))
    await Timer(4, units="ns")
    # Make TARGET 14 in S domain, hart = 2, prio =  1
    # IT SHOULD NOT TAKE EFFECT!!!
    axi_write_reg(dut, TARGET_S_BASE+(TARGET_OFF * 13), (3 << 18) | (2 << 0))
    await Timer(4, units="ns")

    # Make idelivery active in M domain
    axi_write_reg(dut, IDELIVERY_M_BASE, 1)
    await Timer(4, units="ns")
    # Make idelivery active in S domain
    axi_write_reg(dut, IDELIVERY_S_BASE, 1)
    await Timer(4, units="ns")

    # Make ithreshold 1 in M domain
    axi_write_reg(dut, ITHRESHOLD_M_BASE, 1)
    await Timer(4, units="ns")
    # Make ithreshold 2 in S domain
    axi_write_reg(dut, ITHRESHOLD_S_BASE, 2)
    await Timer(4, units="ns")

    # New value of topi. Comes from notifier
    # Write into M domain IDC zero the value 14
    # (26*IDC)+((26*MAX_NUM_IDCS)*DOMAIN)
    dut.i_topi.value = (14 << ((26*0)+((26*1)*0)))
    await Timer(4, units="ns")
    # Enable the update
    dut.i_topi_update.value = (1 << 0)
    await Timer(4, units="ns")
    dut.i_topi_update.value = (0 << 0)

    # Write into S domain IDC zero the value 23
    # (26*IDC)+((26*MAX_NUM_IDCS)*DOMAIN)
    dut.i_topi.value = (23 << ((26*0)+((26*1)*1)))
    await Timer(4, units="ns")
    # Enable the update
    dut.i_topi_update.value = (1 << 1)
    await Timer(4, units="ns")
    dut.i_topi_update.value = (0 << 1)
    
    # Claim the interrupt by reading claimi
    axi_read_reg(dut, CLAIMI_M_BASE)
    await Timer(4, units="ns")
    # Claim the interrupt by reading claimi
    axi_read_reg(dut, CLAIMI_S_BASE)
    await Timer(4, units="ns")

    # Force an interrupt by writing to iforce
    axi_write_reg(dut, IFORCE_M_BASE, 1)
    await Timer(4, units="ns")



async def generate_clock(dut):
    """Generate clock pulses."""

    for cycle in range(100000):
        dut.i_clk.value = 0
        await Timer(1, units="ns")
        dut.i_clk.value = 1
        await Timer(1, units="ns")

@cocotb.test()
async def regctl_unit_test(dut):
    """Try accessing the design."""

    dut.ni_rst.value = 1
    # run the clock "in the background"
    await cocotb.start(generate_clock(dut))  
    # wait a bit
    await Timer(2, units="ns")  
    # wait for falling edge/"negedge"
    await FallingEdge(dut.i_clk)

    # Reset the dut
    dut.ni_rst.value = 0
    await Timer(1, units="ns")
    dut.ni_rst.value = 1
    await Timer(1, units="ns")

    # await cocotb.start(test_domaincfg(dut))
    await cocotb.start(test_every_register(dut))
    
    await Timer(10000, units="ns")