#ifndef ELEMENTSKERNEL_SLEEP_H_
#define ELEMENTSKERNEL_SLEEP_H_

#include <cstdint>
#include "ElementsKernel/Export.h" // ELEMENTS_API

namespace Elements {

/// Simple sleep function.
/// @author Marco Clemencic
ELEMENTS_API void normalSleep(int sec);

/// Small variation on the sleep function for nanoseconds sleep.
/// @author Marco Clemencic
ELEMENTS_API void nanoSleep(int64_t nsec);

}

#endif /*ELEMENTSKERNEL_SLEEP_H_*/
