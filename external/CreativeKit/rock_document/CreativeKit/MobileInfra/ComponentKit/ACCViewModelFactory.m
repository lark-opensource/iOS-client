//
//  ACCViewModelFactory.m
//  CameraClient
//
//  Created by Liu Deping on 2020/7/12.
//

#import "ACCViewModelFactory.h"
#import "ACCViewModel.h"

@interface ACCViewModelFactory ()

@property (nonatomic, strong) id<IESServiceProvider> context;

@end

@implementation ACCViewModelFactory

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    if (self = [super init]) {
        _context = context;
    }
    return self;
}

- (id)createViewModel:(Class)modelClass
{
    id<ACCBusinessInputData> inputData = IESAutoInline(self.context, ACCBusinessInputData);
    NSAssert(inputData, @"input data cannot be nil");
    NSAssert([modelClass conformsToProtocol:@protocol(ACCViewModel)], @"viewModel should confirms to ACCViewModel protocol");
    
    if ([modelClass conformsToProtocol:@protocol(ACCViewModel)]) {
        id<ACCViewModel> viewModel = [[modelClass alloc] init];
        viewModel.inputData = inputData;
        viewModel.repository = inputData.publishModel;
        viewModel.serviceProvider = IESAutoInline(self.context, IESServiceProvider);
        return viewModel;
    }
    return nil;
}

@end
