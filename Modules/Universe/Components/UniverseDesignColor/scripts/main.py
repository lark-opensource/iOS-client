import colorBase
import colorStore
import colorToken
import colorOC
import colorGradient
import colorTools

colorBase.generate_udcolor_basecolor_file()
colorStore.generate_udcolor_store_file()
colorToken.generate_udcolor_token_file()
colorOC.generate_udcolor_basecolor_file()
colorOC.generate_udcolor_token_file()
colorGradient.generate_udcolor_gradient_file()
colorTools.delete_cache()
