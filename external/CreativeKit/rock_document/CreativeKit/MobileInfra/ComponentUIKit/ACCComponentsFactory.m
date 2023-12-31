//
//  ACCComponentsFactory.m
//  CameraClient
//
//  Created by Liu Deping on 2020/7/12.
//

#import "ACCComponentsFactory.h"
#import "ACCFeatureComponent.h"
#import "ACCComponentManager.h"
#import "ACCFeatureComponentPlugin.h"
#import "ACCGlobalTemplateMap.h"
#import "ACCExternalBussinessTemplate.h"

@interface ACCComponentsFactory ()

@property (nonatomic, strong) id<IESServiceProvider> context;

@end

@implementation ACCComponentsFactory

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    if (self = [super init]) {
        _context = context;
    }
    return self;
}

- (void)assemblyComponent:(ACCFeatureComponent *)theFeatureComponent {
    id<IESServiceRegister> serviceRegister = IESAutoInline(self.context, IESServiceRegister);
    if ([theFeatureComponent respondsToSelector:@selector(serviceBinding)]) {
        ACCServiceBinding *serviceBinding = [theFeatureComponent serviceBinding];
        if (serviceBinding.serciceProtocol) {
            [serviceRegister registerInstance:serviceBinding.serviceImpl forProtocol:serviceBinding.serciceProtocol];
        } else if (serviceBinding.serciceProtocols) {
            [serviceRegister registerInstance:serviceBinding.serviceImpl forProtocols:serviceBinding.serciceProtocols];
        }
    }
    if ([theFeatureComponent respondsToSelector:@selector(serviceBindingArray)]) {
        NSArray <ACCServiceBinding *> *serviceBindingArray = [theFeatureComponent serviceBindingArray];
        for (ACCServiceBinding *serviceBinding in serviceBindingArray) {
            if (serviceBinding.serciceProtocol) {
                [serviceRegister registerInstance:serviceBinding.serviceImpl forProtocol:serviceBinding.serciceProtocol];
            } else if (serviceBinding.serciceProtocols) {
                [serviceRegister registerInstance:serviceBinding.serviceImpl forProtocols:serviceBinding.serciceProtocols];
            }
        }
    }
}

- (id)componentWithClass:(Class)clazz
{
    NSAssert([clazz conformsToProtocol:@protocol(ACCFeatureComponent)], @"component should confirms to ACCFeatureComponent protocol");
    
    if ([clazz isSubclassOfClass:[ACCFeatureComponent class]]) {
        ACCFeatureComponent *theFeatureComponent = [[clazz alloc] initWithContext:self.context];
        [self assemblyComponent:theFeatureComponent];
        return theFeatureComponent;
    } else {
        NSAssert(NO, @"custom feature component is not supported yet");
        return nil;
    }
}

- (void)loadComponents
{
    id<ACCBusinessTemplate> businessTemplate = IESAutoInline(self.context, ACCBusinessTemplate);
    NSMutableArray *componentClasses = [businessTemplate componentClasses].mutableCopy;
    NSMutableArray *componentPluginClasses = [[NSMutableArray alloc] init];
    if ([businessTemplate respondsToSelector:@selector(componentPluginClasses)]) {
        NSArray *pluginClass = [businessTemplate componentPluginClasses];
        if (pluginClass.count > 0) {
            [componentPluginClasses addObjectsFromArray:pluginClass];
        }
    }
    
    NSArray *externalBusinessTemplateClasses = [ACCGlobalTemplateMap() resolveExternalTemplateWithInternalTemplate:businessTemplate.class];
    for (ACCBusinessTemplateClass externalBusinessTemplateclass in externalBusinessTemplateClasses) {
        id <ACCBusinessTemplate> externalTemplate;
        if ([externalBusinessTemplateclass isSubclassOfClass:[ACCExternalBussinessTemplate class]]) {
            externalTemplate = [[externalBusinessTemplateclass alloc] initWithContext:self.context];
        } else if ([externalBusinessTemplateclass conformsToProtocol:@protocol(ACCBusinessTemplate)]) {
            externalTemplate = [[externalBusinessTemplateclass alloc] init];
        } else {
            NSCAssert([externalBusinessTemplateclass conformsToProtocol:@protocol(ACCBusinessTemplate)], @"%@ should conforms to ACCBusinessTemplate or be a subclass of ACCExternalBussinessTemplate", [externalBusinessTemplateclass class]);
        }
        
        NSArray *externalComponentClasses = [externalTemplate componentClasses];
        if (externalComponentClasses.count > 0) {
            [componentClasses addObjectsFromArray:externalComponentClasses];
        }
        
        if ([externalTemplate respondsToSelector:@selector(componentPluginClasses)]) {
            NSArray *pluginClass = [externalTemplate componentPluginClasses];
            if (pluginClass.count > 0) {
                [componentPluginClasses addObjectsFromArray:pluginClass];
            }
        }
    }
    
    id<ACCComponentManager> componentManager = IESAutoInline(self.context, ACCComponentManager);
    
    NSMapTable<ACCFeatureComponentClass, ACCFeatureComponent *> *componentRegistry = [NSMapTable strongToStrongObjectsMapTable];
    for (Class aComponentClass in componentClasses) {
        if ([componentRegistry objectForKey:aComponentClass] != nil) {
            continue;
        }

        id component = [self componentWithClass:aComponentClass];
        if (component) {
            [componentManager addComponent:component];
            [componentRegistry setObject:component forKey:aComponentClass];
        }
    }
    
    NSMutableArray<id<ACCFeatureComponentPlugin>> *componentPlugins = [NSMutableArray array];
    for (ACCFeatureComponentPluginClass componentPluginClass in componentPluginClasses) {
        id componentPlugin = nil;
        if ([componentPluginClass isSubclassOfClass:[ACCFeatureComponent class]]) {
            if ([componentRegistry objectForKey:componentPluginClass] != nil) {
                continue;
            }

            componentPlugin = [self componentWithClass:componentPluginClass];
            if (componentPlugin) {
                [componentManager addComponent:componentPlugin];
                [componentRegistry setObject:componentPlugin forKey:componentPluginClass];
            }
        } else {
            componentPlugin = [[componentPluginClass alloc] init];
        }
        if (componentPlugin) {
            [componentPlugins addObject:componentPlugin];
        }
    }
    
    for (ACCFeatureComponent *component in componentRegistry.objectEnumerator) {
        [component bindServices:component.serviceProvider];
    }
    
    for (id<ACCFeatureComponentPlugin> componentPlugin in componentPlugins) {
        ACCFeatureComponent *hostComponent = [componentRegistry objectForKey:[[componentPlugin class] hostIdentifier]];
        if (hostComponent == nil) {
            continue;
        }
        componentPlugin.component = hostComponent;
        
        if ([componentPlugin respondsToSelector:@selector(bindServices:)] &&
            // If the plugin is subclass of ACCFeatureComponet, bindServices: has been called before
            ![componentPlugin isKindOfClass:[ACCFeatureComponent class]]) {
            NSCAssert([componentPlugin conformsToProtocol:@protocol(ACCServiceBindable)], @"%@ should conforms to ACCServiceBindable if it'd like to bind services", componentPlugin);
            [(id<ACCServiceBindable>)componentPlugin bindServices:hostComponent.serviceProvider];
        }
        if ([componentPlugin respondsToSelector:@selector(bindToComponent:)]) {
            [componentPlugin bindToComponent:hostComponent];
        }
        [componentManager bindLife:componentPlugin with:hostComponent];
    }
}

@end
