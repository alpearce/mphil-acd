extern void __writeString(char* s);
extern void __writeHex(unsigned long long n);
extern void __writeDigit(unsigned long long n);
extern char __box_start;

void * kernelEntry;

void common_handler()
{
  long long val;
  long long op1;
  long long op2;
  long long tmp;
  asm volatile("move %0, $a0":"=r" (op1));
  asm volatile("move %0, $a1":"=r" (op2));
  // On any syscall, switch to user mode and jump to the address in $a0.
  asm volatile("mfc0 %0, $13": "=r" (val));
  val = ((val>>2)&0x1f);
  switch(val) {
    case 8: // Syscall, switch to kernel mode
      asm ("dmfc0 %0, $12": "=r" (val)); // Get status register.
      asm ("dmfc0 $k0, $30");
      asm ("dmtc0 $k0, $14");
      val &= 0xffffffffffffffe7; // Mask off the privilege bits (to kernel mode, b'00)
      asm ("dmtc0 %0, $12": : "r" (val)); // Write the status register.
      break;
    case 13: // On any trap, switch to user mode and jump to the address in $a1.
      // The order is kind of scrambled to reduce pipeline stalls.
      // The rule is that a dmtc0 needs ~5 cycles before the next
      // c0 operation commits.
      asm ("dmfc0 $k0, $14"); // Save the kernel return point.
      asm ("daddi $k0, $k0, 4");
      asm ("dmfc0 %0, $12": "=r" (val)); // Get status register.
      asm ("dmtc0 %0, $14": : "r" (op2)); // Set the userspace one.
      val &= 0xffffffffffffffe7; // Mask off the privilege bits.
      val |= 0x10; // Set user mode. (b'10)
      asm ("dmtc0 $k0, $30");
      asm ("move $a0, %0": :"r" (op1));
      asm ("dmtc0 %0, $12": : "r" (val)); // Write the status register.
      break;
    default:
      // EPC
      asm volatile("dmfc0 %0, $14": "=r" (val));
      __writeString("\nException! \nVictim:");
      __writeHex(val);
      val += 4;
      asm volatile("dmtc0 %0, $14": :"r" (val));
      // Cause
      asm volatile("mfc0 %0, $13": "=r" (val));
      val = ((val>>2)&0x1f);
      __writeString("\nCause:");
      __writeDigit(val);
      // Bad Virtual Address
      asm volatile("mfc0 %0, $8": "=r" (val));
      __writeString("\nBad Virtual Address:");
      __writeHex(val);
      // Capability Cause and Register
      asm volatile("CGetCause %0": "=r" (val));
      __writeString("\nCap Cause:");
      val = ((val>>8)&0xff);
      __writeDigit(val);
      asm volatile("CGetCause %0": "=r" (val));
      __writeString("    Cap Reg:");
      val = (val&0xff);
      __writeDigit(val);
      __writeString("\n");
      break;
  }
}

void tlb_handler()
{
  long long *record;
  long long entryLo;
  long long *boxBase;
  long long *badVAddr;
  asm volatile("dli %0, 0x0000000040004000": "=r" (boxBase));
  asm volatile("dmfc0 %0, $8": "=r" (badVAddr));
  if (badVAddr < boxBase) return;
  // EPC
  asm volatile("dmfc0 %0, $20": "=r" (record));
  record = (long long *)((long long)record|0x9800000001000000);
  if (record[0] == 0) {
    asm volatile("mfc0 %0, $10": "=r" (entryLo));
    entryLo = entryLo >> 6;
    // Mask off the bottom configuration bits (6)
    // as well as the least significant PFN .
    entryLo &= ~0x7F;
    // Set up cached, dirty, valid and not global.
    entryLo |= 0x1E;
    // Write the even page entry
    record[0] = entryLo;
    // Write the odd page entry
    entryLo |= 0x40; 
    record[1] = entryLo;
  }
  entryLo = record[0];
  asm volatile("dmtc0 %0, $2": :"r" (entryLo));
  entryLo = record[1];
  asm volatile("dmtc0 %0, $3": :"r" (entryLo));
  asm volatile("tlbwr");
}
