#import "PubgLoad.h"
#import "metalbiew.h"
#include <substrate.h>
#include <mach-o/dyld.h>

// ========== ANTI-DEBUG/ANTI-CHEAT BYPASS ==========
// By ONURCAN MOD - Jailbreak Detection Bypass
static int (*orig_sysctl)(int *, u_int, void *, size_t *, void *, size_t);
static int hook_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (oldp && oldlenp) {
        memset(oldp, 0, *oldlenp);
    }
    return 0;
}

static int (*orig_ptrace)(int, pid_t, caddr_t, int);
static int hook_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    return 0;
}

__attribute__((constructor))
static void init_antidebug() {
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    void *sysctl_addr = (void *)(base + 0x00121C30);
    void *ptrace_addr = (void *)(base + 0x00121D88);
    MSHookFunction(sysctl_addr, (void *)&hook_sysctl, (void **)&orig_sysctl);
    MSHookFunction(ptrace_addr, (void *)&hook_ptrace, (void **)&orig_ptrace);
}
// ========== END ANTI-DEBUG ==========

extern bool MenDeal;
//  Created by Telegram @CheatBot_Owner
@interface ImGuiLoad()
@property (nonatomic, strong) metalbiew *vna;
@end

@implementation ImGuiLoad

+ (void)load
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //  Created by Telegram @CheatBot_Owner
        // [[self share] show];
        [[self share] initTapGes];
    });
}


+ (instancetype)share
{
    static ImGuiLoad *tool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[ImGuiLoad alloc] init];
    });
    return tool;
}
-(void)initTapGes
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.numberOfTapsRequired = 3;//点击次数
    tap.numberOfTouchesRequired = 3;//手指数
    [[UIApplication sharedApplication].windows[0].rootViewController.view addGestureRecognizer:tap];
    [tap addTarget:self action:@selector(show)];
}
- (void)show
{
    if (!_vna) {
        metalbiew *vc = [[metalbiew alloc] init];
        _vna = vc;
    }
    if(MenDeal==true)MenDeal=false;
    else {
        MenDeal=true;
        [[UIApplication sharedApplication].windows[0].rootViewController.view addSubview:_vna.view];}
    
}



@end
