const imgStatesDisabledSizeH24SelectedFalse = "https://www.figma.com/api/mcp/asset/9ff181c1-aa4d-4bd8-9917-47e6755c9f1a.svg";
const imgImage1583515858 = "https://www.figma.com/api/mcp/asset/4d56124c-067a-45fa-8dd9-0f58d6d79712.png";
const imgImage1583515859 = "https://www.figma.com/api/mcp/asset/fb78ee28-4f72-44e1-af94-a310fc9e2848.png";
const imgImage1583515842 = "https://www.figma.com/api/mcp/asset/2e406f37-83da-4fdc-b44c-38cd45b62826.png";
const imgShapes = "https://www.figma.com/api/mcp/asset/0bc9a14d-4080-48c3-8639-10664e6307b4.svg";
const imgNotch = "https://www.figma.com/api/mcp/asset/de6998c3-4bd0-43f7-8d79-b0b4e02ab0eb.svg";
const imgRightSide = "https://www.figma.com/api/mcp/asset/4f4ff078-eaed-468b-b7a4-f54218c7d0c0.svg";
const imgMIconSystemIconCross = "https://www.figma.com/api/mcp/asset/cdcce9ba-b8b7-4e85-84e4-2d3ac9d7b565.svg";
const imgVector20745 = "https://www.figma.com/api/mcp/asset/206b9e3c-23d1-4f20-af6d-d86d5b625d3e.svg";
const imgGroup2147241961 = "https://www.figma.com/api/mcp/asset/0ec6e1a7-b81b-4e9c-a1c7-9782d14e59de.svg";
const imgComponent217 = "https://www.figma.com/api/mcp/asset/aa343a39-b757-4314-8689-741569b0040a.svg";
const imgMCheckbox = "https://www.figma.com/api/mcp/asset/9794f413-2fc9-493f-8866-dc316ad50a1c.svg";
const imgLine199 = "https://www.figma.com/api/mcp/asset/8400e1b9-6686-49ff-a1d1-26566afdd9d5.svg";
const imgGroup1261154791 = "https://www.figma.com/api/mcp/asset/0c9e4a6c-6481-4bd4-9165-88fa9fff0341.svg";
const imgComponent218 = "https://www.figma.com/api/mcp/asset/95e27f0f-ddf4-44f6-ac9f-31ba8bfcf00c.svg";
const imgLine200 = "https://www.figma.com/api/mcp/asset/2b5a27a1-92e0-48b2-b01c-fea7d9947774.svg";

type MCheckboxProps = {
  className?: string;
  selected?: boolean;
  size?: "H24";
  states?: "Disabled";
};

function MCheckbox({ className, selected = false, size = "H24", states = "Disabled" }: MCheckboxProps) {
  return (
    <div className={className || "max-h-[24px] max-w-[24px] min-h-[24px] min-w-[24px] relative size-[24px]"} data-node-id="726:13433">
      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgStatesDisabledSizeH24SelectedFalse} />
    </div>
  );
}

type CardTextProps = {
  className?: string;
  property1?: "Unselected";
};

function CardText({ className, property1 = "Unselected" }: CardTextProps) {
  return (
    <div className={className || "content-stretch flex items-center justify-center relative w-[122.095px]"} data-node-id="983:16687">
      <div className="flex h-[18.658px] items-center justify-center relative shrink-0 w-[122.095px]" data-node-id="983:16688">
        <div className="flex-none rotate-[-0.31deg]">
          <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Noontree:Medium')] justify-center leading-[0] not-italic overflow-hidden relative text-[color:var(--neutral\/black,#0e0e0e)] text-[length:var(--fontsize\/label3,14px)] text-ellipsis tracking-[var(--letterspacing\/label3,-0.14px)] whitespace-nowrap" style={{ fontFeatureSettings: '"case" 1' }}>
            <p className="leading-[var(--lineheight\/label3,18px)] overflow-hidden text-[14px] text-ellipsis">Ayush’s Dubai Place</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Step9() {
  return (
    <div className="bg-[var(--colour\/surface\/primary,white)] overflow-clip relative rounded-[var(--radius\/40,40px)] size-full" data-node-id="1015:45592" data-name="Step 9">
      <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[#b693fd] from-[8.884%] h-[235px] left-1/2 overflow-clip to-[#f9f3fc] to-[114.99%] top-0 w-[375px]" data-node-id="1015:45593" data-name="Background Image">
        <div className="-translate-x-1/2 absolute bottom-[31.62px] h-[223.68px] left-[calc(50%+0.13px)] w-[379.757px]" data-node-id="1015:45594" data-name="Shapes">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgShapes} />
        </div>
        <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[61.401%] from-[rgba(255,255,255,0)] h-[235.699px] left-[calc(50%+0.13px)] to-white top-0 w-[375px]" data-node-id="1015:45599" data-name="White Overlay" />
      </div>
      <div className="absolute h-[47px] left-[0.5px] overflow-clip top-0 w-[375px]" data-node-id="1015:45600" data-name="ios StatusBar">
        <div className="-translate-x-1/2 absolute h-[32px] left-1/2 top-[-2px] w-[164px]" data-node-id="I1015:45600;86:27601" data-name="Notch">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgNotch} />
        </div>
        <div className="absolute contents left-[27px] top-[14px]" data-node-id="I1015:45600;86:27603" data-name="Left Side">
          <div className="absolute h-[21px] left-[27px] rounded-[24px] top-[14px] w-[54px]" data-node-id="I1015:45600;86:27604" data-name="_StatusBar-time">
            <p className="-translate-x-1/2 [word-break:break-word] absolute font-['SF_Pro_Text:Semibold'] h-[20px] leading-[22px] left-[27px] not-italic text-[17px] text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-center top-px tracking-[-0.408px] w-[54px]" data-node-id="I1015:45600;86:27604;839:7100">
              9:41
            </p>
          </div>
        </div>
        <div className="absolute h-[13px] right-[26.6px] top-[19px] w-[77.401px]" data-node-id="I1015:45600;86:27605" data-name="Right Side">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgRightSide} />
        </div>
      </div>
      <div className="absolute content-stretch flex gap-[12px] h-[56px] items-center left-0 px-[var(--space\/16,16px)] py-[var(--gap\/8,8px)] top-[47px] w-[375px]" data-node-id="1015:45601" data-name="header stack">
        <div className="backdrop-blur-[26px] bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/primary,#eaecf0)] border-solid content-stretch flex items-center justify-center overflow-clip px-[4.8px] py-[3.2px] relative rounded-[7999.2px] shrink-0 size-[40px]" data-node-id="1015:45602" data-name="Back button">
          <div className="relative shrink-0 size-[20px]" data-node-id="1015:45603" data-name="M-Icon/System-Icon/cross">
            <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMIconSystemIconCross} />
          </div>
        </div>
        <div className="content-stretch flex flex-[1_0_0] flex-col gap-[var(--space\/8,8px)] h-full items-center justify-center min-w-px overflow-clip pr-[var(--space\/48,48px)] relative" data-node-id="1015:45604" data-name="Content">
          <div className="bg-[rgba(255,255,255,0.4)] content-stretch flex flex-col h-[4px] items-start overflow-clip relative rounded-[8px] shrink-0 w-[72px]" data-node-id="1015:45606">
            <div className="bg-white flex-[1_0_0] min-h-px relative rounded-[8px] w-[60.907px]" data-node-id="1015:45607" />
          </div>
        </div>
      </div>
      <div className="-translate-x-1/2 absolute content-stretch flex flex-col items-center left-[calc(50%-0.5px)] pb-[8px] top-[103px] w-[374px]" data-node-id="1015:45608" data-name="Header">
        <div className="h-[125px] mb-[-48px] relative shrink-0 w-[235px]" data-node-id="1015:45609" data-name="Address Asset">
          <div className="absolute flex h-[134.811px] items-center justify-center left-[8.21px] top-[-23.58px] w-[218.577px]" data-node-id="1015:45610">
            <div className="-scale-y-100 flex-none rotate-[22.73deg]">
              <div className="h-[56.879px] relative w-[213.152px]">
                <div className="absolute inset-[-5.36%_-0.58%_-12.64%_-0.54%]">
                  <img alt="" className="block max-w-none size-full" src={imgVector20745} />
                </div>
              </div>
            </div>
          </div>
          <div className="-translate-x-1/2 absolute h-[113.96px] left-1/2 top-[-1.65px] w-[71.453px]" data-node-id="1015:45611" data-name="image 1583515858">
            <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515858} />
          </div>
          <div className="absolute h-[39.57px] left-[131.48px] top-[13.02px] w-[37.485px]" data-node-id="1015:45612">
            <div className="absolute inset-[-7.74%_-8.17%]">
              <img alt="" className="block max-w-none size-full" src={imgGroup2147241961} />
            </div>
          </div>
          <div className="absolute flex h-[60.043px] items-center justify-center left-[50.3px] top-[27.4px] w-[66.138px]" data-node-id="1015:45616">
            <div className="flex-none rotate-[31.42deg]">
              <div className="h-[36.716px] relative w-[55.074px]" data-name="image 1583515859">
                <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515859} />
              </div>
            </div>
          </div>
          <div className="absolute left-[45.07px] size-[46.87px] top-[-6.39px]" data-node-id="1015:45617" data-name="image 1583515842">
            <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515842} />
          </div>
        </div>
        <div className="[word-break:break-word] content-stretch flex flex-col gap-[2px] items-center relative shrink-0 text-center w-full" data-node-id="1015:45618" data-name="texts">
          <p className="bg-clip-text font-[family-name:var(--base\/font\/family\/primary,'Noontree:ExtraBold')] font-[var(--base\/font\/weight\/extrabold,normal)] leading-[var(--font\/heading\/h40\/line-height,48px)] min-w-full relative shrink-0 text-[length:var(--font\/heading\/h40\/size,40px)] text-[transparent] text-shadow-[0px_1px_7px_rgba(0,0,0,0.15)] tracking-[var(--font\/heading\/h40\/letter-spacing,-0.25px)] w-[min-content]" data-node-id="1015:45619" style={{ backgroundImage: "linear-gradient(28.681407930172938deg, rgb(0, 0, 0) 52.835%, rgb(121, 36, 255) 104.2%)" }}>
            Add Address
          </p>
          <div className="flex flex-col font-[family-name:var(--base\/font\/family\/primary,'Noontree:Medium')] font-[var(--base\/font\/weight\/medium,normal)] justify-center leading-[0] overflow-hidden relative shrink-0 text-[color:var(--colour\/text-n-icon\/secondary,#475067)] text-[length:var(--font\/body\/b14\/size,14px)] text-ellipsis tracking-[var(--font\/body\/b14\/letter-spacing,-0.1px)] w-[311.28px]" data-node-id="1015:45620">
            <p className="leading-[var(--font\/body\/b14\/line-height,20px)] text-[14px]">Select a saved address. Kiaan can add more later</p>
          </div>
        </div>
      </div>
      <div className="-translate-x-1/2 absolute content-stretch flex flex-col gap-[var(--space\/20,20px)] items-start left-1/2 px-[var(--space\/16,16px)] py-[var(--space\/20,20px)] top-[258px] w-[375px]" data-node-id="1015:45621">
        <div className="content-stretch flex flex-col gap-[12px] items-start relative shrink-0 w-full" data-node-id="1015:45625" data-name="Address card">
          <div className="bg-[#f0f0f5] border border-[#f6dbff] border-solid content-stretch flex flex-col items-start overflow-clip relative rounded-[var(--radius\/16,16px)] shadow-[0px_0px_0px_2px_#fcf5fe] shrink-0 w-full" data-node-id="1015:45626" data-name="Address cards">
            <div className="bg-[#fcf0ff] content-stretch flex h-[45px] items-center justify-between pl-[8px] pr-[4px] py-[8px] relative shrink-0 w-full" data-node-id="1015:45627" data-name="Top unit">
              <div className="content-stretch flex flex-[1_0_0] items-center justify-between min-w-px relative" data-node-id="1015:45628" data-name="Address header">
                <div className="content-stretch flex gap-[8px] items-center relative shrink-0" data-node-id="1015:45629" data-name="Address info">
                  <div className="bg-[var(--neutral\/white,white)] border border-[rgba(246,219,255,0.1)] border-solid drop-shadow-[0px_12.889px_14.844px_rgba(0,0,0,0.02)] relative rounded-[8px] shrink-0 size-[29px]" data-node-id="1015:45630" data-name="Card icon">
                    <div className="-translate-x-1/2 -translate-y-1/2 absolute left-1/2 size-[20px] top-1/2" data-node-id="I1015:45630;4360:17234" data-name="Component 217">
                      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgComponent217} />
                    </div>
                  </div>
                  <div className="content-stretch flex items-center relative shrink-0" data-node-id="1015:45631" data-name="Card text">
                    <div className="flex h-[18.658px] items-center justify-center relative shrink-0 w-[122.095px]" data-node-id="I1015:45631;4360:17319">
                      <div className="flex-none rotate-[-0.31deg]">
                        <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Noontree:Medium')] justify-center leading-[0] not-italic overflow-hidden relative text-[color:var(--neutral\/black,#0e0e0e)] text-[length:var(--fontsize\/label3,14px)] text-ellipsis tracking-[var(--letterspacing\/label3,-0.14px)] whitespace-nowrap" style={{ fontFeatureSettings: '"case" 1' }}>
                          <p className="leading-[var(--lineheight\/label3,18px)] overflow-hidden text-[14px] text-ellipsis">Work</p>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="bg-white content-stretch flex items-center justify-center pb-[4px] pl-[7px] pr-[6px] pt-[3px] relative rounded-[6px] shrink-0 w-[37px]" data-node-id="1015:45632" data-name="Card distance">
                    <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Noontree:Bold')] justify-center leading-[0] not-italic relative shrink-0 text-[color:var(--🚧-text\/👀-secondary,rgba(2,6,12,0.6))] text-[length:var(--fontsize\/tiny,10px)] tracking-[var(--letterspacing\/tiny,0px)] whitespace-nowrap" data-node-id="I1015:45632;4364:17350">
                      <p className="leading-[var(--lineheight\/tiny,12px)]">24 m</p>
                    </div>
                  </div>
                </div>
                <div className="content-stretch flex items-center px-[var(--space\/8,8px)] relative shrink-0" data-node-id="1015:45633" data-name="Checkbox">
                  <div className="max-h-[20px] max-w-[20px] min-h-[20px] min-w-[20px] relative shrink-0 size-[20px]" data-node-id="1015:45634" data-name="M-Checkbox">
                    <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMCheckbox} />
                  </div>
                </div>
              </div>
            </div>
            <div className="bg-[var(--neutral\/white,white)] content-stretch flex flex-col items-start overflow-clip p-[12px] relative shrink-0 w-full" data-node-id="1015:45635" data-name="Bottom unit">
              <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45635;4368:17454">
                <div className="content-stretch flex flex-col items-center relative shrink-0 w-full" data-node-id="I1015:45635;4368:17455">
                  <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45635;4368:17456">
                    <div className="content-stretch flex flex-col gap-[8px] items-start relative shrink-0 w-full" data-node-id="I1015:45635;4368:17457">
                      <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] min-w-full not-italic overflow-hidden relative shrink-0 text-[13px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] w-[min-content]" data-node-id="I1015:45635;4368:17458">
                        <p className="leading-[17px]">Burj Khalifa, 1 Sheikh Mohammed bin Rashid Blvd, Downtown Dubai</p>
                      </div>
                      <div className="h-0 relative shrink-0 w-full" data-node-id="I1015:45635;4368:17459">
                        <div className="absolute inset-[-1px_0_0_0]">
                          <img alt="" className="block max-w-none size-full" src={imgLine199} />
                        </div>
                      </div>
                      <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45635;4368:17460">
                        <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45635;4368:17461">
                          <div className="content-stretch flex gap-[4px] items-center relative shrink-0" data-node-id="I1015:45635;4368:17462">
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45635;4368:17463" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">Ahmed Ali,</p>
                            </div>
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45635;4368:17464" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">+971-50 789 3456</p>
                            </div>
                            <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45635;4368:17465">
                              <div className="relative shrink-0 size-[14px]" data-node-id="I1015:45635;4368:17466">
                                <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgGroup1261154791} />
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className="bg-[var(--blue-gray\/100,#f9f9fb)] border border-[var(--blue-gray\/300,#eaecf0)] border-solid content-stretch flex flex-col items-start overflow-clip relative rounded-[var(--radius\/16,16px)] shrink-0 w-full" data-node-id="1015:45636" data-name="Address cards">
            <div className="content-stretch flex h-[45px] items-center justify-between pl-[8px] pr-[4px] py-[8px] relative shrink-0 w-full" data-node-id="1015:45637" data-name="Top unit">
              <div className="content-stretch flex flex-[1_0_0] items-center justify-between min-w-px relative" data-node-id="1015:45638" data-name="Address header">
                <div className="content-stretch flex gap-[8px] items-center relative shrink-0" data-node-id="1015:45639" data-name="Address info">
                  <div className="bg-[var(--neutral\/white,white)] border border-[var(--blue-gray\/200,#f2f3f7)] border-solid drop-shadow-[0px_12.889px_14.844px_rgba(0,0,0,0.02)] relative rounded-[8px] shrink-0 size-[29px]" data-node-id="1015:45640" data-name="Card icon">
                    <div className="-translate-x-1/2 -translate-y-1/2 absolute left-1/2 size-[20px] top-1/2" data-node-id="I1015:45640;4360:17234" data-name="Component 217">
                      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgComponent218} />
                    </div>
                  </div>
                  <CardText className="content-stretch flex items-center justify-center relative shrink-0 w-[122.095px]" />
                  <div className="bg-white content-stretch flex items-center justify-center pb-[4px] pl-[7px] pr-[6px] pt-[3px] relative rounded-[6px] shrink-0 w-[37px]" data-node-id="1015:45642" data-name="Card distance">
                    <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Noontree:Bold')] justify-center leading-[0] not-italic relative shrink-0 text-[color:var(--blue-gray\/700,#475067)] text-[length:var(--fontsize\/tiny,10px)] tracking-[var(--letterspacing\/tiny,0px)] whitespace-nowrap" data-node-id="I1015:45642;4364:17350">
                      <p className="leading-[var(--lineheight\/tiny,12px)]">24 m</p>
                    </div>
                  </div>
                </div>
                <div className="content-stretch flex items-center px-[var(--space\/8,8px)] relative shrink-0" data-node-id="1015:45643" data-name="Checkbox">
                  <MCheckbox className="max-h-[24px] max-w-[24px] min-h-[24px] min-w-[24px] relative shrink-0 size-[24px]" />
                </div>
              </div>
            </div>
            <div className="bg-[var(--neutral\/white,white)] content-stretch flex flex-col items-start overflow-clip p-[12px] relative shrink-0 w-full" data-node-id="1015:45645" data-name="Bottom unit">
              <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45645;4368:17454">
                <div className="content-stretch flex flex-col items-center relative shrink-0 w-full" data-node-id="I1015:45645;4368:17455">
                  <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45645;4368:17456">
                    <div className="content-stretch flex flex-col gap-[8px] items-start relative shrink-0 w-full" data-node-id="I1015:45645;4368:17457">
                      <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] min-w-full not-italic overflow-hidden relative shrink-0 text-[13px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] w-[min-content]" data-node-id="I1015:45645;4368:17458">
                        <p className="leading-[17px]">Burj Khalifa, 1 Sheikh Mohammed bin Rashid Blvd, Downtown Dubai</p>
                      </div>
                      <div className="h-0 relative shrink-0 w-full" data-node-id="I1015:45645;4368:17459">
                        <div className="absolute inset-[-1px_0_0_0]">
                          <img alt="" className="block max-w-none size-full" src={imgLine199} />
                        </div>
                      </div>
                      <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45645;4368:17460">
                        <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45645;4368:17461">
                          <div className="content-stretch flex gap-[4px] items-center relative shrink-0" data-node-id="I1015:45645;4368:17462">
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45645;4368:17463" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">Ahmed Ali,</p>
                            </div>
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45645;4368:17464" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">+971-50 789 3456</p>
                            </div>
                            <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45645;4368:17465">
                              <div className="relative shrink-0 size-[14px]" data-node-id="I1015:45645;4368:17466">
                                <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgGroup1261154791} />
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className="bg-[var(--blue-gray\/100,#f9f9fb)] border border-[var(--blue-gray\/300,#eaecf0)] border-solid content-stretch flex flex-col items-start overflow-clip relative rounded-[var(--radius\/16,16px)] shrink-0 w-full" data-node-id="1015:45646" data-name="Address cards">
            <div className="content-stretch flex h-[45px] items-center justify-between pl-[8px] pr-[4px] py-[8px] relative shrink-0 w-full" data-node-id="1015:45647" data-name="Top unit">
              <div className="content-stretch flex flex-[1_0_0] items-center justify-between min-w-px relative" data-node-id="1015:45648" data-name="Address header">
                <div className="content-stretch flex gap-[8px] items-center relative shrink-0" data-node-id="1015:45649" data-name="Address info">
                  <div className="bg-[var(--neutral\/white,white)] border border-[var(--blue-gray\/200,#f2f3f7)] border-solid drop-shadow-[0px_12.889px_14.844px_rgba(0,0,0,0.02)] relative rounded-[8px] shrink-0 size-[29px]" data-node-id="1015:45650" data-name="Card icon">
                    <div className="-translate-x-1/2 -translate-y-1/2 absolute left-1/2 size-[20px] top-1/2" data-node-id="I1015:45650;4360:17234" data-name="Component 217">
                      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgComponent218} />
                    </div>
                  </div>
                  <CardText className="content-stretch flex items-center justify-center relative shrink-0 w-[122.095px]" />
                  <div className="bg-white content-stretch flex items-center justify-center pb-[4px] pl-[7px] pr-[6px] pt-[3px] relative rounded-[6px] shrink-0 w-[37px]" data-node-id="1015:45652" data-name="Card distance">
                    <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Noontree:Bold')] justify-center leading-[0] not-italic relative shrink-0 text-[color:var(--blue-gray\/700,#475067)] text-[length:var(--fontsize\/tiny,10px)] tracking-[var(--letterspacing\/tiny,0px)] whitespace-nowrap" data-node-id="I1015:45652;4364:17350">
                      <p className="leading-[var(--lineheight\/tiny,12px)]">24 m</p>
                    </div>
                  </div>
                </div>
                <div className="content-stretch flex items-center px-[var(--space\/8,8px)] relative shrink-0" data-node-id="1015:45653" data-name="Checkbox">
                  <MCheckbox className="max-h-[24px] max-w-[24px] min-h-[24px] min-w-[24px] relative shrink-0 size-[24px]" />
                </div>
              </div>
            </div>
            <div className="bg-[var(--neutral\/white,white)] content-stretch flex flex-col items-start overflow-clip p-[12px] relative shrink-0 w-full" data-node-id="1015:45655" data-name="Bottom unit">
              <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45655;4368:17454">
                <div className="content-stretch flex flex-col items-center relative shrink-0 w-full" data-node-id="I1015:45655;4368:17455">
                  <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45655;4368:17456">
                    <div className="content-stretch flex flex-col gap-[8px] items-start relative shrink-0 w-full" data-node-id="I1015:45655;4368:17457">
                      <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] min-w-full not-italic overflow-hidden relative shrink-0 text-[13px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] w-[min-content]" data-node-id="I1015:45655;4368:17458">
                        <p className="leading-[17px]">Burj Khalifa, 1 Sheikh Mohammed bin Rashid Blvd, Downtown Dubai</p>
                      </div>
                      <div className="h-0 relative shrink-0 w-full" data-node-id="I1015:45655;4368:17459">
                        <div className="absolute inset-[-1px_0_0_0]">
                          <img alt="" className="block max-w-none size-full" src={imgLine199} />
                        </div>
                      </div>
                      <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45655;4368:17460">
                        <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45655;4368:17461">
                          <div className="content-stretch flex gap-[4px] items-center relative shrink-0" data-node-id="I1015:45655;4368:17462">
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45655;4368:17463" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">Ahmed Ali,</p>
                            </div>
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45655;4368:17464" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">+971-50 789 3456</p>
                            </div>
                            <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45655;4368:17465">
                              <div className="relative shrink-0 size-[14px]" data-node-id="I1015:45655;4368:17466">
                                <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgGroup1261154791} />
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="absolute flex h-[20px] items-center justify-center left-[182px] top-[47px] w-0" data-node-id="1015:45656">
          <div className="flex-none rotate-90">
            <div className="h-0 relative w-[20px]">
              <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgLine200} />
            </div>
          </div>
        </div>
      </div>
      <div className="absolute bottom-0 content-stretch drop-shadow-[0px_-167px_23.5px_rgba(224,224,224,0),0px_-107px_21.5px_rgba(224,224,224,0.01),0px_-60px_18px_rgba(224,224,224,0.05),0px_-27px_13.5px_rgba(224,224,224,0.09),0px_-7px_7.5px_rgba(224,224,224,0.1)] flex flex-col items-center justify-center left-0 overflow-clip rounded-tl-[var(--radius\/20,20px)] rounded-tr-[var(--radius\/20,20px)] w-[375px]" data-node-id="1015:45657">
        <div className="bg-[var(--colour\/surface\/primary,white)] content-stretch flex gap-[var(--space\/12,12px)] items-center p-[var(--space\/12,12px)] relative shrink-0 w-[375px]" data-node-id="1015:45658" data-name="M-RowActionBar">
          <div className="bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/primary,#eaecf0)] border-solid content-stretch flex flex-[1_0_0] gap-[var(--space\/8,8px)] items-center justify-center max-h-[52px] min-h-[52px] min-w-px px-[var(--space\/20,20px)] py-[var(--space\/14,14px)] relative rounded-[var(--radius\/12,12px)]" data-node-id="I1015:45658;1735:95" data-name="M-SecondaryNeutralButton">
            <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/action\/a16\/line-height,24px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-[length:var(--font\/action\/a16\/size,16px)] tracking-[var(--font\/action\/a16\/letter-spacing,0px)] whitespace-nowrap" data-node-id="I1015:45658;1735:95;944:12597">
              Back
            </p>
          </div>
          <div className="border border-[#e0e0e0] border-solid content-stretch flex flex-[1_0_0] gap-[var(--space\/8,8px)] items-center justify-center max-h-[52px] min-h-[52px] min-w-px overflow-clip px-[var(--gap\/14,14px)] py-[var(--space\/14,14px)] relative rounded-[var(--radius\/12,12px)]" data-node-id="I1015:45658;1735:101" data-name="M-NeutralButton">
            <div aria-hidden className="absolute bg-gradient-to-b from-[#2a2c2e] inset-0 pointer-events-none rounded-[var(--radius\/12,12px)] to-[#101112]" />
            <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/action\/a16\/line-height,24px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/on-surface-bold,white)] text-[length:var(--font\/action\/a16\/size,16px)] tracking-[var(--font\/action\/a16\/letter-spacing,0px)] whitespace-nowrap" data-node-id="I1015:45658;1735:101;752:90">
              Continue
            </p>
            <div className="absolute inset-0 pointer-events-none rounded-[inherit] shadow-[inset_0px_-14.667px_14.667px_0px_#0c0d0e,inset_0px_14.667px_14.667px_0px_#2e2f32]" />
          </div>
        </div>
        <div className="bg-[var(--colour\/surface\/primary,white)] h-[24px] relative shrink-0 w-full" data-node-id="1015:45659" data-name="Home bar">
          <div className="absolute bg-[#262a33] inset-[41.67%_33.33%_37.5%_33.6%] rounded-[8px]" data-node-id="1015:45660" data-name="Home bar" />
        </div>
      </div>
    </div>
  );
}
