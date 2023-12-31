//
//  macro.h
//  Hermas
//
//  Created by 崔晓兵 on 7/9/2022.
//

#ifndef macro_h
#define macro_h

#if HERMAS_USE_EXCEPTION
#else
#define throw
#define try          if(true)
#define catch(...)   if(false)
#endif


#endif /* macro_h */
