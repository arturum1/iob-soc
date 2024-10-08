#pragma once
#include <stdbool.h>
#include "iob_nco_swreg.h"

// Functions
void nco_reset();
void nco_init(uint32_t base_address);
void nco_enable(bool enable);
void nco_set_period(uint32_t period);
