const imgStateDefault = "https://www.figma.com/api/mcp/asset/10d0a7b8-cfbb-4778-9620-f47725322152.svg";
const imgStyleDashedEmphasisLow = "https://www.figma.com/api/mcp/asset/fad4203a-896c-4c9c-8bbe-2a25d0de9da8.svg";
const imgImage1583516005 = "https://www.figma.com/api/mcp/asset/b5b2b446-08bf-4e46-957b-9b3dd612e294.png";
const imgImage1583515842 = "https://www.figma.com/api/mcp/asset/3d020907-1f03-411b-a698-9500df04f5e7.png";
const imgImage1583515993 = "https://www.figma.com/api/mcp/asset/e5dd6e26-c70b-4131-a2b4-f896f3359745.png";
const imgImage1583515994 = "https://www.figma.com/api/mcp/asset/8e6d85aa-4f79-4322-8bc5-369a35e289d6.png";
const imgShapes = "https://www.figma.com/api/mcp/asset/beb1b581-7694-418e-901e-6271586d023b.svg";
const imgNotch = "https://www.figma.com/api/mcp/asset/72e1931e-1b0c-427f-95e4-c8f8ef94f847.svg";
const imgRightSide = "https://www.figma.com/api/mcp/asset/9b89adaf-c6af-43ce-b09f-966ef3d14677.svg";
const imgMIconSystemIconCross = "https://www.figma.com/api/mcp/asset/72b19c0d-41e4-4490-91a7-64127d580176.svg";
const imgVector20745 = "https://www.figma.com/api/mcp/asset/ede40e06-5546-4be2-b642-79261a53538e.svg";
const imgGroup2147241961 = "https://www.figma.com/api/mcp/asset/a62ed159-508d-4acb-8bfb-e9413eecc6ab.svg";
const imgMDivider = "https://www.figma.com/api/mcp/asset/3790992a-3137-479d-b526-3e4f7d1b78e0.svg";
const imgRadio = "https://www.figma.com/api/mcp/asset/ecdadbf7-5845-4ac4-b742-1866e983df7d.svg";
const imgLine200 = "https://www.figma.com/api/mcp/asset/ff276839-55aa-421a-93ad-d555400e2e88.svg";

type RadioProps = {
  className?: string;
  state?: "default";
};

function Radio({ className, state = "default" }: RadioProps) {
  return (
    <div className={className || "relative size-[20px]"} data-node-id="993:39822">
      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgStateDefault} />
    </div>
  );
}

type MDividerProps = {
  className?: string;
  emphasis?: "Low";
  style?: "Dashed";
};

function MDivider({ className, emphasis = "Low", style = "Dashed" }: MDividerProps) {
  return (
    <div className={className || "h-px relative w-[351px]"} data-node-id="375:4943">
      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgStyleDashedEmphasisLow} />
    </div>
  );
}

export default function Step7() {
  return (
    <div className="bg-[var(--colour\/surface\/primary,white)] overflow-clip relative rounded-[var(--radius\/40,40px)] size-full" data-node-id="1015:45823" data-name="Step 7">
      <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[#b693fd] from-[8.884%] h-[235px] left-1/2 overflow-clip to-[#f9f3fc] to-[114.99%] top-0 w-[375px]" data-node-id="1015:45824" data-name="Background Image">
        <div className="-translate-x-1/2 absolute bottom-[31.62px] h-[223.68px] left-[calc(50%+0.13px)] w-[379.757px]" data-node-id="1015:45825" data-name="Shapes">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgShapes} />
        </div>
        <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[61.401%] from-[rgba(255,255,255,0)] h-[235.699px] left-[calc(50%+0.13px)] to-white top-0 w-[375px]" data-node-id="1015:45830" data-name="White Overlay" />
      </div>
      <div className="absolute h-[47px] left-[0.5px] overflow-clip top-0 w-[375px]" data-node-id="1015:45831" data-name="ios StatusBar">
        <div className="-translate-x-1/2 absolute h-[32px] left-1/2 top-[-2px] w-[164px]" data-node-id="I1015:45831;86:27601" data-name="Notch">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgNotch} />
        </div>
        <div className="absolute contents left-[27px] top-[14px]" data-node-id="I1015:45831;86:27603" data-name="Left Side">
          <div className="absolute h-[21px] left-[27px] rounded-[24px] top-[14px] w-[54px]" data-node-id="I1015:45831;86:27604" data-name="_StatusBar-time">
            <p className="-translate-x-1/2 [word-break:break-word] absolute font-['SF_Pro_Text:Semibold'] h-[20px] leading-[22px] left-[27px] not-italic text-[17px] text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-center top-px tracking-[-0.408px] w-[54px]" data-node-id="I1015:45831;86:27604;839:7100">
              9:41
            </p>
          </div>
        </div>
        <div className="absolute h-[13px] right-[26.6px] top-[19px] w-[77.401px]" data-node-id="I1015:45831;86:27605" data-name="Right Side">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgRightSide} />
        </div>
      </div>
      <div className="absolute content-stretch flex gap-[12px] h-[56px] items-center left-0 px-[var(--space\/16,16px)] py-[var(--gap\/8,8px)] top-[47px] w-[375px]" data-node-id="1015:45832" data-name="header stack">
        <div className="backdrop-blur-[26px] bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/primary,#eaecf0)] border-solid content-stretch flex items-center justify-center overflow-clip px-[4.8px] py-[3.2px] relative rounded-[7999.2px] shrink-0 size-[40px]" data-node-id="1015:45833" data-name="Back button">
          <div className="relative shrink-0 size-[20px]" data-node-id="1015:45834" data-name="M-Icon/System-Icon/cross">
            <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMIconSystemIconCross} />
          </div>
        </div>
        <div className="content-stretch flex flex-[1_0_0] flex-col gap-[var(--space\/8,8px)] h-full items-center justify-center min-w-px overflow-clip pr-[var(--space\/48,48px)] relative" data-node-id="1015:45835" data-name="Content">
          <div className="bg-[rgba(255,255,255,0.4)] content-stretch flex flex-col h-[4px] items-start overflow-clip relative rounded-[8px] shrink-0 w-[72px]" data-node-id="1015:45837">
            <div className="bg-white flex-[1_0_0] min-h-px relative rounded-[8px] w-[60.907px]" data-node-id="1015:45838" />
          </div>
        </div>
      </div>
      <div className="-translate-x-1/2 absolute content-stretch flex flex-col items-center left-1/2 pb-[8px] top-[103px] w-[374px]" data-node-id="1015:45839" data-name="Header">
        <div className="h-[125px] mb-[-48px] relative shrink-0 w-[235px]" data-node-id="1015:45840" data-name="asset">
          <div className="absolute flex h-[95.817px] items-center justify-center left-[18.08px] top-[3.26px] w-[210.424px]" data-node-id="1015:45841">
            <div className="flex-none rotate-[-12.11deg]">
              <div className="h-[54.319px] relative w-[203.559px]">
                <div className="absolute inset-[-5.61%_-0.61%_-13.24%_-0.57%]">
                  <img alt="" className="block max-w-none size-full" src={imgVector20745} />
                </div>
              </div>
            </div>
          </div>
          <div className="absolute contents left-[53.75px] top-[-2.97px]" data-node-id="1015:45842">
            <div className="absolute h-[102.326px] left-[74.36px] top-[-2.97px] w-[90.917px]" data-node-id="1015:45843" data-name="image 1583516005">
              <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583516005} />
            </div>
            <div className="absolute left-[53.75px] size-[60.677px] top-[32.16px]" data-node-id="1015:45844" data-name="image 1583515842">
              <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515842} />
            </div>
            <div className="absolute h-[48.562px] left-[136.06px] top-[5.9px] w-[46.004px]" data-node-id="1015:45845">
              <div className="absolute inset-[-7.49%_-7.91%_-7.49%_-7.9%]">
                <img alt="" className="block max-w-none size-full" src={imgGroup2147241961} />
              </div>
            </div>
          </div>
        </div>
        <div className="[word-break:break-word] content-stretch flex flex-col gap-[2px] items-center relative shrink-0 text-center w-full" data-node-id="1015:45849" data-name="texts">
          <p className="bg-clip-text font-[family-name:var(--base\/font\/family\/primary,'Noontree:ExtraBold')] font-[var(--base\/font\/weight\/extrabold,normal)] leading-[var(--font\/heading\/h40\/line-height,48px)] min-w-full relative shrink-0 text-[length:var(--font\/heading\/h40\/size,40px)] text-[transparent] text-shadow-[0px_1px_7px_rgba(0,0,0,0.15)] tracking-[var(--font\/heading\/h40\/letter-spacing,-0.25px)] w-[min-content]" data-node-id="1015:45850" style={{ backgroundImage: "linear-gradient(28.681407930172938deg, rgb(0, 0, 0) 52.835%, rgb(121, 36, 255) 104.2%)" }}>
            Set Rules
          </p>
          <div className="flex flex-col font-[family-name:var(--base\/font\/family\/primary,'Noontree:Medium')] font-[var(--base\/font\/weight\/medium,normal)] justify-center leading-[0] overflow-hidden relative shrink-0 text-[color:var(--colour\/text-n-icon\/secondary,#475067)] text-[length:var(--font\/body\/b14\/size,14px)] text-ellipsis tracking-[var(--font\/body\/b14\/letter-spacing,-0.1px)] w-[311.28px]" data-node-id="1015:45851">
            <p className="leading-[var(--font\/body\/b14\/line-height,20px)] text-[14px]">Set up approval rules for shopping</p>
          </div>
        </div>
      </div>
      <div className="-translate-x-1/2 absolute content-stretch flex flex-col gap-[var(--space\/20,20px)] items-start left-1/2 px-[var(--space\/16,16px)] py-[var(--space\/20,20px)] top-[258px] w-[375px]" data-node-id="1015:45852">
        <div className="content-stretch drop-shadow-[0px_0px_0px_#d8e5ff] flex flex-col gap-[var(--space\/16,16px)] items-start overflow-clip relative rounded-[var(--radius\/12,12px)] shrink-0 w-full" data-node-id="1015:45856" data-name="Option Container">
          <div className="bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/subtle,#f2f3f7)] border-solid content-stretch flex gap-[var(--space\/12,12px)] items-center overflow-clip p-[var(--space\/12,12px)] relative rounded-[16px] shrink-0 w-full" data-node-id="1015:45857" data-name="Auto-approve orders">
            <div className="content-stretch flex flex-[1_0_0] flex-col gap-[12px] items-start justify-center min-w-px relative" data-node-id="1015:45858" data-name="Left">
              <div className="content-stretch flex items-start justify-between py-[var(--space\/0,0px)] relative shrink-0 w-full" data-node-id="1015:45859" data-name="Action">
                <div className="h-[56px] relative shrink-0 w-[56.005px]" data-node-id="1015:45860" data-name="image 1583515993">
                  <div className="absolute inset-0 overflow-hidden pointer-events-none">
                    <img alt="" className="absolute h-[116.67%] left-[-8.33%] max-w-none top-[-5.42%] w-[116.66%]" src={imgImage1583515993} />
                  </div>
                </div>
                <Radio className="relative shrink-0 size-[20px]" />
              </div>
              <div className="[word-break:break-word] content-stretch flex flex-col gap-[3px] items-start relative shrink-0 w-full" data-node-id="1015:45862" data-name="Content Container">
                <p className="font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/body\/b16\/line-height,22px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-[length:var(--font\/body\/b16\/size,16px)] tracking-[var(--font\/body\/b16\/letter-spacing,-0.15px)] w-full" data-node-id="1015:45863">
                  Auto-approve orders
                </p>
                <p className="font-[family-name:var(--base\/font\/family\/primary,'Noontree:Regular')] font-[var(--base\/font\/weight\/regular,normal)] leading-[var(--font\/body\/b13\/line-height,20px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/secondary,#475067)] text-[length:var(--font\/body\/b13\/size,13px)] tracking-[var(--font\/body\/b13\/letter-spacing,-0.1px)] w-full" data-node-id="1015:45864">
                  Kiaan can place orders using available wallet balance
                </p>
              </div>
            </div>
          </div>
          <div className="border border-[#f6dbff] border-solid content-stretch flex flex-col gap-[var(--space\/24,24px)] items-start justify-center overflow-clip p-[var(--space\/12,12px)] relative rounded-[16px] shrink-0 w-full" data-node-id="1015:45865" style={{ backgroundImage: "linear-gradient(180deg, rgb(255, 255, 255) 0%, rgb(251, 240, 255) 100%), linear-gradient(180.0000027958543deg, rgb(252, 246, 254) 40.795%, rgb(248, 224, 255) 100%)" }} data-name="Option Container">
            <div className="content-stretch flex flex-col gap-[12px] items-start justify-center relative shrink-0 w-full" data-node-id="1015:45866">
              <div className="content-stretch flex items-start justify-between py-[var(--space\/0,0px)] relative shrink-0 w-full" data-node-id="1015:45867" data-name="Action">
                <div className="relative shrink-0 size-[56px]" data-node-id="1015:45868" data-name="image 1583515994">
                  <div className="absolute inset-0 overflow-hidden pointer-events-none">
                    <img alt="" className="absolute left-[-7.74%] max-w-none size-[116.04%] top-[-7.9%]" src={imgImage1583515994} />
                  </div>
                </div>
                <Radio className="relative shrink-0 size-[20px]" />
              </div>
              <div className="[word-break:break-word] content-stretch flex flex-col gap-[3px] items-start relative shrink-0 w-full" data-node-id="1015:45870">
                <p className="font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/body\/b16\/line-height,22px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-[length:var(--font\/body\/b16\/size,16px)] tracking-[var(--font\/body\/b16\/letter-spacing,-0.15px)] w-full" data-node-id="1015:45871">
                  Manually approve orders
                </p>
                <p className="font-[family-name:var(--base\/font\/family\/primary,'Noontree:Regular')] font-[var(--base\/font\/weight\/regular,normal)] leading-[var(--font\/body\/b13\/line-height,20px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/secondary,#475067)] text-[length:var(--font\/body\/b13\/size,13px)] tracking-[var(--font\/body\/b13\/letter-spacing,-0.1px)] w-full" data-node-id="1015:45872">
                  Approve all orders or those over a specific amount.
                </p>
              </div>
            </div>
            <div className="h-px relative shrink-0 w-full" data-node-id="1015:45873" data-name="M-Divider">
              <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMDivider} />
            </div>
            <div className="content-stretch flex flex-col gap-[8px] items-start relative shrink-0 w-full" data-node-id="1015:45874" data-name="More Actions">
              <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:Regular')] font-[var(--base\/font\/weight\/regular,normal)] leading-[var(--font\/body\/b14\/line-height,20px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/secondary,#475067)] text-[length:var(--font\/body\/b14\/size,14px)] tracking-[var(--font\/body\/b14\/letter-spacing,-0.1px)] w-full" data-node-id="1015:45875">
                Select one
              </p>
              <div className="bg-[var(--colour\/surface\/primary,white)] content-stretch flex flex-col gap-[12px] items-start justify-center p-[var(--space\/16,16px)] relative rounded-[var(--radius\/12,12px)] shrink-0 w-full" data-node-id="1015:45876" data-name="Inputs">
                <div className="content-stretch flex flex-col gap-[var(--space\/12,12px)] items-start relative shrink-0 w-full" data-node-id="1015:45877" data-name="Task info">
                  <div className="content-stretch flex gap-[var(--space\/8,8px)] items-center justify-center relative shrink-0 w-full" data-node-id="1015:45878">
                    <p className="[word-break:break-word] flex-[1_0_0] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/body\/b14\/line-height,20px)] min-w-px overflow-hidden relative text-[14px] text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-ellipsis tracking-[var(--font\/body\/b14\/letter-spacing,-0.1px)] whitespace-nowrap" data-node-id="1015:45879">
                      Above an order limit
                    </p>
                    <div className="relative shrink-0 size-[20px]" data-node-id="1015:45880" data-name="Radio">
                      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgRadio} />
                    </div>
                  </div>
                  <div className="bg-[var(--colour\/surface\/secondary,#f9f9fb)] border border-[var(--colour\/border\/primary,#eaecf0)] border-solid content-stretch flex gap-[var(--space\/8,8px)] items-center max-h-[56px] min-h-[56px] px-[var(--space\/12,12px)] py-[var(--space\/8,8px)] relative rounded-[var(--radius\/16,16px)] shrink-0 w-full" data-node-id="1015:45881" data-name="Field">
                    <div className="content-stretch flex flex-[1_0_0] flex-col gap-[var(--space\/2,2px)] items-start justify-center min-w-px relative" data-node-id="1015:45882">
                      <div className="content-stretch flex gap-[2px] items-center overflow-clip relative shrink-0 w-full" data-node-id="1015:45886" data-name="Content">
                        <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/body\/b14\/line-height,20px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-[length:var(--font\/body\/b14\/size,14px)] tracking-[var(--font\/body\/b14\/letter-spacing,-0.1px)] whitespace-nowrap" data-node-id="1015:45887">
                          dhm 120
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
                <MDivider className="h-px relative shrink-0 w-full" />
                <div className="content-stretch flex gap-[var(--space\/12,12px)] items-center px-[var(--space\/0,0px)] py-[var(--space\/8,8px)] relative shrink-0 w-full" data-node-id="1015:45891" data-name="Task Card">
                  <p className="[word-break:break-word] flex-[1_0_0] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/body\/b14\/line-height,20px)] min-w-px overflow-hidden relative text-[14px] text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-ellipsis tracking-[var(--font\/body\/b14\/letter-spacing,-0.1px)] whitespace-nowrap" data-node-id="1015:45892">
                    For every order
                  </p>
                  <Radio className="relative shrink-0 size-[20px]" />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="absolute flex h-[20px] items-center justify-center left-[182px] top-[47px] w-0" data-node-id="1015:45894">
          <div className="flex-none rotate-90">
            <div className="h-0 relative w-[20px]">
              <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgLine200} />
            </div>
          </div>
        </div>
      </div>
      <div className="absolute bottom-0 content-stretch drop-shadow-[0px_-167px_23.5px_rgba(224,224,224,0),0px_-107px_21.5px_rgba(224,224,224,0.01),0px_-60px_18px_rgba(224,224,224,0.05),0px_-27px_13.5px_rgba(224,224,224,0.09),0px_-7px_7.5px_rgba(224,224,224,0.1)] flex flex-col items-center justify-center left-0 overflow-clip rounded-tl-[var(--radius\/20,20px)] rounded-tr-[var(--radius\/20,20px)] w-[375px]" data-node-id="1015:45895">
        <div className="bg-[var(--colour\/surface\/primary,white)] content-stretch flex gap-[var(--space\/12,12px)] items-center p-[var(--space\/12,12px)] relative shrink-0 w-[375px]" data-node-id="1015:45896" data-name="M-RowActionBar">
          <div className="bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/primary,#eaecf0)] border-solid content-stretch flex flex-[1_0_0] gap-[var(--space\/8,8px)] items-center justify-center max-h-[52px] min-h-[52px] min-w-px px-[var(--space\/20,20px)] py-[var(--space\/14,14px)] relative rounded-[var(--radius\/12,12px)]" data-node-id="I1015:45896;1735:95" data-name="M-SecondaryNeutralButton">
            <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/action\/a16\/line-height,24px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-[length:var(--font\/action\/a16\/size,16px)] tracking-[var(--font\/action\/a16\/letter-spacing,0px)] whitespace-nowrap" data-node-id="I1015:45896;1735:95;944:12597">
              Back
            </p>
          </div>
          <div className="border border-[#e0e0e0] border-solid content-stretch flex flex-[1_0_0] gap-[var(--space\/8,8px)] items-center justify-center max-h-[52px] min-h-[52px] min-w-px overflow-clip px-[var(--gap\/14,14px)] py-[var(--space\/14,14px)] relative rounded-[var(--radius\/12,12px)]" data-node-id="I1015:45896;1735:101" data-name="M-NeutralButton">
            <div aria-hidden className="absolute bg-gradient-to-b from-[#2a2c2e] inset-0 pointer-events-none rounded-[var(--radius\/12,12px)] to-[#101112]" />
            <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/action\/a16\/line-height,24px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/on-surface-bold,white)] text-[length:var(--font\/action\/a16\/size,16px)] tracking-[var(--font\/action\/a16\/letter-spacing,0px)] whitespace-nowrap" data-node-id="I1015:45896;1735:101;752:90">
              Continue
            </p>
            <div className="absolute inset-0 pointer-events-none rounded-[inherit] shadow-[inset_0px_-14.667px_14.667px_0px_#0c0d0e,inset_0px_14.667px_14.667px_0px_#2e2f32]" />
          </div>
        </div>
        <div className="bg-[var(--colour\/surface\/primary,white)] h-[24px] relative shrink-0 w-full" data-node-id="1015:45897" data-name="Home bar">
          <div className="absolute bg-[#262a33] inset-[41.67%_33.33%_37.5%_33.6%] rounded-[8px]" data-node-id="1015:45898" data-name="Home bar" />
        </div>
      </div>
    </div>
  );
}
