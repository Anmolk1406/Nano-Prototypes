const imgStateDefault = "https://www.figma.com/api/mcp/asset/7525cd34-ae48-440e-a410-a02b626bf9d2.svg";
const imgImage1583516005 = "https://www.figma.com/api/mcp/asset/d3b72d9d-375e-4199-ab3c-66fd1e5469e0.png";
const imgImage1583515842 = "https://www.figma.com/api/mcp/asset/dce44b08-feda-49ad-af94-8a95aada842e.png";
const imgImage1583515994 = "https://www.figma.com/api/mcp/asset/253826ea-5f4d-4847-81bf-85d84905e2ed.png";
const imgImage1583515995 = "https://www.figma.com/api/mcp/asset/917f9099-a786-4a0f-8565-7a094eccc793.png";
const imgShapes = "https://www.figma.com/api/mcp/asset/b87ac65f-488b-4acd-bd73-c71104de713f.svg";
const imgNotch = "https://www.figma.com/api/mcp/asset/6e3bbda4-17f9-4bb4-bcf7-e292279d0faa.svg";
const imgRightSide = "https://www.figma.com/api/mcp/asset/c924a2f6-735b-46b7-aa2d-b5b6a0e5a3ac.svg";
const imgMIconSystemIconCross = "https://www.figma.com/api/mcp/asset/2bebf46b-39a8-470a-bd5a-4c7b2f6addfe.svg";
const imgVector20745 = "https://www.figma.com/api/mcp/asset/debe9424-7ed5-409d-bacd-10479f4fafc3.svg";
const imgGroup2147241961 = "https://www.figma.com/api/mcp/asset/236cdf04-1e85-4163-b8d9-75c590239ea6.svg";
const imgRadio = "https://www.figma.com/api/mcp/asset/6a761a50-9f6f-49de-96e2-11b275f851c7.svg";
const imgLine200 = "https://www.figma.com/api/mcp/asset/dbb2be91-1e55-4028-89ba-ed5f1c84599d.svg";

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

export default function Step6() {
  return (
    <div className="bg-[var(--colour\/surface\/primary,white)] overflow-clip relative rounded-[var(--radius\/40,40px)] size-full" data-node-id="1015:45974" data-name="Step 6">
      <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[#b693fd] from-[8.884%] h-[235px] left-1/2 overflow-clip to-[#f9f3fc] to-[114.99%] top-0 w-[375px]" data-node-id="1015:45975" data-name="Background Image">
        <div className="-translate-x-1/2 absolute bottom-[31.62px] h-[223.68px] left-[calc(50%+0.13px)] w-[379.757px]" data-node-id="1015:45976" data-name="Shapes">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgShapes} />
        </div>
        <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[61.401%] from-[rgba(255,255,255,0)] h-[235.699px] left-[calc(50%+0.13px)] to-white top-0 w-[375px]" data-node-id="1015:45981" data-name="White Overlay" />
      </div>
      <div className="absolute h-[47px] left-[0.5px] overflow-clip top-0 w-[375px]" data-node-id="1015:45982" data-name="ios StatusBar">
        <div className="-translate-x-1/2 absolute h-[32px] left-1/2 top-[-2px] w-[164px]" data-node-id="I1015:45982;86:27601" data-name="Notch">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgNotch} />
        </div>
        <div className="absolute contents left-[27px] top-[14px]" data-node-id="I1015:45982;86:27603" data-name="Left Side">
          <div className="absolute h-[21px] left-[27px] rounded-[24px] top-[14px] w-[54px]" data-node-id="I1015:45982;86:27604" data-name="_StatusBar-time">
            <p className="-translate-x-1/2 [word-break:break-word] absolute font-['SF_Pro_Text:Semibold'] h-[20px] leading-[22px] left-[27px] not-italic text-[17px] text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-center top-px tracking-[-0.408px] w-[54px]" data-node-id="I1015:45982;86:27604;839:7100">
              9:41
            </p>
          </div>
        </div>
        <div className="absolute h-[13px] right-[26.6px] top-[19px] w-[77.401px]" data-node-id="I1015:45982;86:27605" data-name="Right Side">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgRightSide} />
        </div>
      </div>
      <div className="absolute content-stretch flex gap-[12px] h-[56px] items-center left-0 px-[var(--space\/16,16px)] py-[var(--gap\/8,8px)] top-[47px] w-[375px]" data-node-id="1015:45983" data-name="header stack">
        <div className="backdrop-blur-[26px] bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/primary,#eaecf0)] border-solid content-stretch flex items-center justify-center overflow-clip px-[4.8px] py-[3.2px] relative rounded-[7999.2px] shrink-0 size-[40px]" data-node-id="1015:45984" data-name="Back button">
          <div className="relative shrink-0 size-[20px]" data-node-id="1015:45985" data-name="M-Icon/System-Icon/cross">
            <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMIconSystemIconCross} />
          </div>
        </div>
        <div className="content-stretch flex flex-[1_0_0] flex-col gap-[var(--space\/8,8px)] h-full items-center justify-center min-w-px overflow-clip pr-[var(--space\/48,48px)] relative" data-node-id="1015:45986" data-name="Content">
          <div className="bg-[rgba(255,255,255,0.4)] content-stretch flex flex-col h-[4px] items-start overflow-clip relative rounded-[8px] shrink-0 w-[72px]" data-node-id="1015:45988">
            <div className="bg-white flex-[1_0_0] min-h-px relative rounded-[8px] w-[60.907px]" data-node-id="1015:45989" />
          </div>
        </div>
      </div>
      <div className="-translate-x-1/2 absolute content-stretch flex flex-col items-center left-[calc(50%-0.5px)] pb-[8px] top-[103px] w-[374px]" data-node-id="1015:45990" data-name="Header">
        <div className="h-[125px] mb-[-48px] relative shrink-0 w-[235px]" data-node-id="1015:45991" data-name="asset">
          <div className="absolute flex h-[95.817px] items-center justify-center left-[18.08px] top-[3.26px] w-[210.424px]" data-node-id="1015:45992">
            <div className="flex-none rotate-[-12.11deg]">
              <div className="h-[54.319px] relative w-[203.559px]">
                <div className="absolute inset-[-5.61%_-0.61%_-13.24%_-0.57%]">
                  <img alt="" className="block max-w-none size-full" src={imgVector20745} />
                </div>
              </div>
            </div>
          </div>
          <div className="absolute contents left-[53.75px] top-[-2.97px]" data-node-id="1015:45993">
            <div className="absolute h-[102.326px] left-[74.36px] top-[-2.97px] w-[90.917px]" data-node-id="1015:45994" data-name="image 1583516005">
              <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583516005} />
            </div>
            <div className="absolute left-[53.75px] size-[60.677px] top-[32.16px]" data-node-id="1015:45995" data-name="image 1583515842">
              <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515842} />
            </div>
            <div className="absolute h-[48.562px] left-[136.06px] top-[5.9px] w-[46.004px]" data-node-id="1015:45996">
              <div className="absolute inset-[-7.49%_-7.91%_-7.49%_-7.9%]">
                <img alt="" className="block max-w-none size-full" src={imgGroup2147241961} />
              </div>
            </div>
          </div>
        </div>
        <div className="[word-break:break-word] content-stretch flex flex-col gap-[2px] items-center relative shrink-0 text-center w-full" data-node-id="1015:46000" data-name="texts">
          <p className="bg-clip-text font-[family-name:var(--base\/font\/family\/primary,'Noontree:ExtraBold')] font-[var(--base\/font\/weight\/extrabold,normal)] leading-[var(--font\/heading\/h40\/line-height,48px)] min-w-full relative shrink-0 text-[length:var(--font\/heading\/h40\/size,40px)] text-[transparent] text-shadow-[0px_1px_7px_rgba(0,0,0,0.15)] tracking-[var(--font\/heading\/h40\/letter-spacing,-0.25px)] w-[min-content]" data-node-id="1015:46001" style={{ backgroundImage: "linear-gradient(28.681407930172938deg, rgb(0, 0, 0) 52.835%, rgb(121, 36, 255) 104.2%)" }}>
            Set Rules
          </p>
          <div className="flex flex-col font-[family-name:var(--base\/font\/family\/primary,'Noontree:Medium')] font-[var(--base\/font\/weight\/medium,normal)] justify-center leading-[0] overflow-hidden relative shrink-0 text-[color:var(--colour\/text-n-icon\/secondary,#475067)] text-[length:var(--font\/body\/b14\/size,14px)] text-ellipsis tracking-[var(--font\/body\/b14\/letter-spacing,-0.1px)] w-[311.28px]" data-node-id="1015:46002">
            <p className="leading-[var(--font\/body\/b14\/line-height,20px)] text-[14px]">Set up approval rules for shopping</p>
          </div>
        </div>
      </div>
      <div className="-translate-x-1/2 absolute content-stretch flex flex-col gap-[var(--space\/20,20px)] items-start left-1/2 px-[var(--space\/16,16px)] py-[var(--space\/20,20px)] top-[258px] w-[375px]" data-node-id="1015:46003">
        <div className="content-stretch drop-shadow-[0px_0px_0px_#d8e5ff] flex flex-col gap-[var(--space\/16,16px)] items-start overflow-clip relative rounded-[var(--radius\/12,12px)] shrink-0 w-full" data-node-id="1015:46007" data-name="Option Container">
          <div className="bg-gradient-to-b border border-[#f6dbff] border-solid content-stretch flex from-white gap-[var(--space\/12,12px)] items-center overflow-clip p-[12px] relative rounded-[16px] shrink-0 to-[#fdf5ff] w-full" data-node-id="1015:46008" data-name="Auto-approve orders">
            <div className="content-stretch flex flex-[1_0_0] flex-col gap-[12px] items-start justify-center min-w-px relative" data-node-id="1015:46009" data-name="Left">
              <div className="content-stretch flex items-start justify-between py-[var(--space\/0,0px)] relative shrink-0 w-full" data-node-id="1015:46010" data-name="Action">
                <div className="h-[56px] relative shrink-0 w-[56.005px]" data-node-id="1015:46011" data-name="image 1583515994">
                  <div className="absolute inset-0 overflow-hidden pointer-events-none">
                    <img alt="" className="absolute h-[116.67%] left-[-8.33%] max-w-none top-[-5.42%] w-[116.66%]" src={imgImage1583515994} />
                  </div>
                </div>
                <div className="relative shrink-0 size-[20px]" data-node-id="1015:46012" data-name="Radio">
                  <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgRadio} />
                </div>
              </div>
              <div className="[word-break:break-word] content-stretch flex flex-col gap-[3px] items-start relative shrink-0 w-full" data-node-id="1015:46013" data-name="Content Container">
                <p className="font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/body\/b16\/line-height,22px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-[length:var(--font\/body\/b16\/size,16px)] tracking-[var(--font\/body\/b16\/letter-spacing,-0.15px)] w-full" data-node-id="1015:46014">
                  Auto-approve orders
                </p>
                <p className="font-[family-name:var(--base\/font\/family\/primary,'Noontree:Regular')] font-[var(--base\/font\/weight\/regular,normal)] leading-[var(--font\/body\/b13\/line-height,20px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/secondary,#475067)] text-[length:var(--font\/body\/b13\/size,13px)] tracking-[var(--font\/body\/b13\/letter-spacing,-0.1px)] w-full" data-node-id="1015:46015">
                  Kiaan can place orders using available wallet balance
                </p>
              </div>
            </div>
          </div>
          <div className="bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/subtle,#f2f3f7)] border-solid content-stretch flex gap-[var(--space\/12,12px)] items-center overflow-clip p-[12px] relative rounded-[16px] shrink-0 w-full" data-node-id="1015:46016" data-name="Option Container">
            <div className="content-stretch flex flex-[1_0_0] flex-col gap-[12px] items-start justify-center min-w-px relative" data-node-id="1015:46017">
              <div className="content-stretch flex items-start justify-between py-[var(--space\/0,0px)] relative shrink-0 w-full" data-node-id="1015:46018" data-name="Action">
                <div className="relative shrink-0 size-[56px]" data-node-id="1015:46019" data-name="image 1583515994">
                  <div className="absolute inset-0 overflow-hidden pointer-events-none">
                    <img alt="" className="absolute left-[-7.74%] max-w-none size-[116.04%] top-[-7.9%]" src={imgImage1583515995} />
                  </div>
                </div>
                <Radio className="relative shrink-0 size-[20px]" />
              </div>
              <div className="[word-break:break-word] content-stretch flex flex-col gap-[3px] items-start relative shrink-0 w-full" data-node-id="1015:46021">
                <p className="font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/body\/b16\/line-height,22px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-[length:var(--font\/body\/b16\/size,16px)] tracking-[var(--font\/body\/b16\/letter-spacing,-0.15px)] w-full" data-node-id="1015:46022">
                  Manually approve orders
                </p>
                <p className="font-[family-name:var(--base\/font\/family\/primary,'Noontree:Regular')] font-[var(--base\/font\/weight\/regular,normal)] leading-[var(--font\/body\/b13\/line-height,20px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/secondary,#475067)] text-[length:var(--font\/body\/b13\/size,13px)] tracking-[var(--font\/body\/b13\/letter-spacing,-0.1px)] w-full" data-node-id="1015:46023">
                  Approve all orders or those over a specific amount.
                </p>
              </div>
            </div>
          </div>
        </div>
        <div className="absolute flex h-[20px] items-center justify-center left-[182px] top-[47px] w-0" data-node-id="1015:46024">
          <div className="flex-none rotate-90">
            <div className="h-0 relative w-[20px]">
              <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgLine200} />
            </div>
          </div>
        </div>
      </div>
      <div className="absolute bottom-0 content-stretch drop-shadow-[0px_-167px_23.5px_rgba(224,224,224,0),0px_-107px_21.5px_rgba(224,224,224,0.01),0px_-60px_18px_rgba(224,224,224,0.05),0px_-27px_13.5px_rgba(224,224,224,0.09),0px_-7px_7.5px_rgba(224,224,224,0.1)] flex flex-col items-center justify-center left-0 overflow-clip rounded-tl-[var(--radius\/20,20px)] rounded-tr-[var(--radius\/20,20px)] w-[375px]" data-node-id="1015:46025">
        <div className="bg-[var(--colour\/surface\/primary,white)] content-stretch flex gap-[var(--space\/12,12px)] items-center p-[var(--space\/12,12px)] relative shrink-0 w-[375px]" data-node-id="1015:46026" data-name="M-RowActionBar">
          <div className="bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/primary,#eaecf0)] border-solid content-stretch flex flex-[1_0_0] gap-[var(--space\/8,8px)] items-center justify-center max-h-[52px] min-h-[52px] min-w-px px-[var(--space\/20,20px)] py-[var(--space\/14,14px)] relative rounded-[var(--radius\/12,12px)]" data-node-id="I1015:46026;1735:95" data-name="M-SecondaryNeutralButton">
            <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/action\/a16\/line-height,24px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-[length:var(--font\/action\/a16\/size,16px)] tracking-[var(--font\/action\/a16\/letter-spacing,0px)] whitespace-nowrap" data-node-id="I1015:46026;1735:95;944:12597">
              Back
            </p>
          </div>
          <div className="border border-[#e0e0e0] border-solid content-stretch flex flex-[1_0_0] gap-[var(--space\/8,8px)] items-center justify-center max-h-[52px] min-h-[52px] min-w-px overflow-clip px-[var(--gap\/14,14px)] py-[var(--space\/14,14px)] relative rounded-[var(--radius\/12,12px)]" data-node-id="I1015:46026;1735:101" data-name="M-NeutralButton">
            <div aria-hidden className="absolute bg-gradient-to-b from-[#2a2c2e] inset-0 pointer-events-none rounded-[var(--radius\/12,12px)] to-[#101112]" />
            <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/action\/a16\/line-height,24px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/on-surface-bold,white)] text-[length:var(--font\/action\/a16\/size,16px)] tracking-[var(--font\/action\/a16\/letter-spacing,0px)] whitespace-nowrap" data-node-id="I1015:46026;1735:101;752:90">
              Continue
            </p>
            <div className="absolute inset-0 pointer-events-none rounded-[inherit] shadow-[inset_0px_-14.667px_14.667px_0px_#0c0d0e,inset_0px_14.667px_14.667px_0px_#2e2f32]" />
          </div>
        </div>
        <div className="bg-[var(--colour\/surface\/primary,white)] h-[24px] relative shrink-0 w-full" data-node-id="1015:46027" data-name="Home bar">
          <div className="absolute bg-[#262a33] inset-[41.67%_33.33%_37.5%_33.6%] rounded-[8px]" data-node-id="1015:46028" data-name="Home bar" />
        </div>
      </div>
    </div>
  );
}
