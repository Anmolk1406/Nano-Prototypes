const imgStatesDisabledSizeH24SelectedFalse = "https://www.figma.com/api/mcp/asset/1dd05091-3873-4628-b3e9-ffbc9dcc084d.svg";
const imgImage1583515858 = "https://www.figma.com/api/mcp/asset/fdca9b7b-2391-4b20-bae9-a292cb6bf23c.png";
const imgImage1583515859 = "https://www.figma.com/api/mcp/asset/e064b28e-8503-444b-ba55-06d703de2161.png";
const imgImage1583515842 = "https://www.figma.com/api/mcp/asset/7bc51897-3096-4542-8fb9-32051434d970.png";
const imgImage1583515817 = "https://www.figma.com/api/mcp/asset/6d2b4826-6261-46b5-a0dc-49cd63637e69.png";
const imgImage1583515818 = "https://www.figma.com/api/mcp/asset/96d463a7-bb58-47a0-8c65-13440f38d9b3.png";
const imgImage1583515815 = "https://www.figma.com/api/mcp/asset/a6516dec-3a29-4e9e-9ae4-33d284e70ab6.png";
const imgImage271146229 = "https://www.figma.com/api/mcp/asset/6a1c01f3-b3ea-47eb-b906-e8f56e003fc9.png";
const imgImage271146307 = "https://www.figma.com/api/mcp/asset/5360794e-a5be-416e-8884-52390f11cc21.png";
const imgImage271146178 = "https://www.figma.com/api/mcp/asset/88673b33-ad78-4360-b9aa-1668d254de8a.png";
const imgImage271146308 = "https://www.figma.com/api/mcp/asset/c95797e7-523e-4ab3-885c-73fda3db18f8.png";
const imgShapes = "https://www.figma.com/api/mcp/asset/7350f31a-1f23-4cee-9855-92311fdd719f.svg";
const imgNotch = "https://www.figma.com/api/mcp/asset/09077837-923c-4ca1-98ca-8e7449d1c100.svg";
const imgRightSide = "https://www.figma.com/api/mcp/asset/de450240-a7d8-4d0e-a096-172bb2a2e3b3.svg";
const imgMIconSystemIconCross = "https://www.figma.com/api/mcp/asset/9b3a5f5d-36dc-48cd-8ed6-f69803dab60e.svg";
const imgVector20745 = "https://www.figma.com/api/mcp/asset/5c59d569-01ad-4aab-bbc5-ba492648d5f8.svg";
const imgGroup2147241961 = "https://www.figma.com/api/mcp/asset/6513d1bc-b264-481e-8b9d-492cc0c8bd27.svg";
const imgComponent217 = "https://www.figma.com/api/mcp/asset/704ae0a3-2e59-4fd4-b656-d654147b8f0d.svg";
const imgMCheckbox = "https://www.figma.com/api/mcp/asset/f0df010e-2c98-4752-9cf8-095c501ed05c.svg";
const imgLine199 = "https://www.figma.com/api/mcp/asset/d2a748bf-ca44-4d6a-bd69-dc6bf02f2a76.svg";
const imgGroup1261154791 = "https://www.figma.com/api/mcp/asset/75072388-54ef-4a61-b12f-52b3c150c611.svg";
const imgComponent218 = "https://www.figma.com/api/mcp/asset/def73f74-f8bf-490f-8b41-99a84a6edf05.svg";
const imgLine200 = "https://www.figma.com/api/mcp/asset/d620832f-9acc-40bf-af5b-96f218793d01.svg";
const imgVector20710 = "https://www.figma.com/api/mcp/asset/68bf4cad-3973-4c05-9c7e-41390804db93.svg";
const imgGroup2147241962 = "https://www.figma.com/api/mcp/asset/2edec75f-8dce-4651-8039-c3288635c4c1.svg";
const imgUnion = "https://www.figma.com/api/mcp/asset/986a997a-bfd0-4a33-8893-27fee38183ac.svg";
const imgVector20714 = "https://www.figma.com/api/mcp/asset/8177a7d7-f300-4bb3-b314-1ef9eb14b9f2.svg";
const imgGroup2147241956 = "https://www.figma.com/api/mcp/asset/e531b6ee-1635-472f-82fd-0da030a2cdce.svg";
const imgVector20711 = "https://www.figma.com/api/mcp/asset/b99ab940-d5fb-4c1b-9aea-f3dde16c2609.svg";
const imgVector20717 = "https://www.figma.com/api/mcp/asset/aa3f768c-b2fc-4171-bfd2-c92da751253f.svg";

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

export default function Step10() {
  return (
    <div className="bg-[var(--colour\/surface\/primary,white)] overflow-clip relative rounded-[var(--radius\/40,40px)] size-full" data-node-id="1015:45661" data-motion-annotations="Asset to be shared from motion side" data-name="Step 10">
      <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[#b693fd] from-[8.884%] h-[235px] left-1/2 overflow-clip to-[#f9f3fc] to-[114.99%] top-0 w-[375px]" data-node-id="1015:45662" data-name="Background Image">
        <div className="-translate-x-1/2 absolute bottom-[31.62px] h-[223.68px] left-[calc(50%+0.13px)] w-[379.757px]" data-node-id="1015:45663" data-name="Shapes">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgShapes} />
        </div>
        <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[61.401%] from-[rgba(255,255,255,0)] h-[235.699px] left-[calc(50%+0.13px)] to-white top-0 w-[375px]" data-node-id="1015:45668" data-name="White Overlay" />
      </div>
      <div className="absolute h-[47px] left-[0.5px] overflow-clip top-0 w-[375px]" data-node-id="1015:45669" data-name="ios StatusBar">
        <div className="-translate-x-1/2 absolute h-[32px] left-1/2 top-[-2px] w-[164px]" data-node-id="I1015:45669;86:27601" data-name="Notch">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgNotch} />
        </div>
        <div className="absolute contents left-[27px] top-[14px]" data-node-id="I1015:45669;86:27603" data-name="Left Side">
          <div className="absolute h-[21px] left-[27px] rounded-[24px] top-[14px] w-[54px]" data-node-id="I1015:45669;86:27604" data-name="_StatusBar-time">
            <p className="-translate-x-1/2 [word-break:break-word] absolute font-['SF_Pro_Text:Semibold'] h-[20px] leading-[22px] left-[27px] not-italic text-[17px] text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-center top-px tracking-[-0.408px] w-[54px]" data-node-id="I1015:45669;86:27604;839:7100">
              9:41
            </p>
          </div>
        </div>
        <div className="absolute h-[13px] right-[26.6px] top-[19px] w-[77.401px]" data-node-id="I1015:45669;86:27605" data-name="Right Side">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgRightSide} />
        </div>
      </div>
      <div className="absolute content-stretch flex gap-[12px] h-[56px] items-center left-0 px-[var(--space\/16,16px)] py-[var(--gap\/8,8px)] top-[47px] w-[375px]" data-node-id="1015:45670" data-name="header stack">
        <div className="backdrop-blur-[26px] bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/primary,#eaecf0)] border-solid content-stretch flex items-center justify-center overflow-clip px-[4.8px] py-[3.2px] relative rounded-[7999.2px] shrink-0 size-[40px]" data-node-id="1015:45671" data-name="Back button">
          <div className="relative shrink-0 size-[20px]" data-node-id="1015:45672" data-name="M-Icon/System-Icon/cross">
            <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMIconSystemIconCross} />
          </div>
        </div>
        <div className="content-stretch flex flex-[1_0_0] flex-col gap-[var(--space\/8,8px)] h-full items-center justify-center min-w-px overflow-clip pr-[var(--space\/48,48px)] relative" data-node-id="1015:45673" data-name="Content">
          <div className="bg-[rgba(255,255,255,0.4)] content-stretch flex flex-col h-[4px] items-start overflow-clip relative rounded-[8px] shrink-0 w-[72px]" data-node-id="1015:45675">
            <div className="bg-white flex-[1_0_0] min-h-px relative rounded-[8px] w-[60.907px]" data-node-id="1015:45676" />
          </div>
        </div>
      </div>
      <div className="-translate-x-1/2 absolute content-stretch flex flex-col items-center left-[calc(50%-0.5px)] pb-[8px] top-[103px] w-[374px]" data-node-id="1015:45677" data-name="Header">
        <div className="h-[125px] mb-[-48px] relative shrink-0 w-[235px]" data-node-id="1015:45678" data-name="Address Asset">
          <div className="absolute flex h-[134.811px] items-center justify-center left-[8.21px] top-[-23.58px] w-[218.577px]" data-node-id="1015:45679">
            <div className="-scale-y-100 flex-none rotate-[22.73deg]">
              <div className="h-[56.879px] relative w-[213.152px]">
                <div className="absolute inset-[-5.36%_-0.58%_-12.64%_-0.54%]">
                  <img alt="" className="block max-w-none size-full" src={imgVector20745} />
                </div>
              </div>
            </div>
          </div>
          <div className="-translate-x-1/2 absolute h-[113.96px] left-1/2 top-[-1.65px] w-[71.453px]" data-node-id="1015:45680" data-name="image 1583515858">
            <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515858} />
          </div>
          <div className="absolute h-[39.57px] left-[131.48px] top-[13.02px] w-[37.485px]" data-node-id="1015:45681">
            <div className="absolute inset-[-7.74%_-8.17%]">
              <img alt="" className="block max-w-none size-full" src={imgGroup2147241961} />
            </div>
          </div>
          <div className="absolute flex h-[60.043px] items-center justify-center left-[50.3px] top-[27.4px] w-[66.138px]" data-node-id="1015:45685">
            <div className="flex-none rotate-[31.42deg]">
              <div className="h-[36.716px] relative w-[55.074px]" data-name="image 1583515859">
                <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515859} />
              </div>
            </div>
          </div>
          <div className="absolute left-[45.07px] size-[46.87px] top-[-6.39px]" data-node-id="1015:45686" data-name="image 1583515842">
            <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515842} />
          </div>
        </div>
        <div className="[word-break:break-word] content-stretch flex flex-col gap-[2px] items-center relative shrink-0 text-center w-full" data-node-id="1015:45687" data-name="texts">
          <p className="bg-clip-text font-[family-name:var(--base\/font\/family\/primary,'Noontree:ExtraBold')] font-[var(--base\/font\/weight\/extrabold,normal)] leading-[var(--font\/heading\/h40\/line-height,48px)] min-w-full relative shrink-0 text-[length:var(--font\/heading\/h40\/size,40px)] text-[transparent] text-shadow-[0px_1px_7px_rgba(0,0,0,0.15)] tracking-[var(--font\/heading\/h40\/letter-spacing,-0.25px)] w-[min-content]" data-node-id="1015:45688" style={{ backgroundImage: "linear-gradient(28.681407930172938deg, rgb(0, 0, 0) 52.835%, rgb(121, 36, 255) 104.2%)" }}>
            Add Address
          </p>
          <div className="flex flex-col font-[family-name:var(--base\/font\/family\/primary,'Noontree:Medium')] font-[var(--base\/font\/weight\/medium,normal)] justify-center leading-[0] overflow-hidden relative shrink-0 text-[color:var(--colour\/text-n-icon\/secondary,#475067)] text-[length:var(--font\/body\/b14\/size,14px)] text-ellipsis tracking-[var(--font\/body\/b14\/letter-spacing,-0.1px)] w-[311.28px]" data-node-id="1015:45689">
            <p className="leading-[var(--font\/body\/b14\/line-height,20px)] text-[14px]">Select a saved address. Kiaan can add more later</p>
          </div>
        </div>
      </div>
      <div className="-translate-x-1/2 absolute content-stretch flex flex-col gap-[var(--space\/20,20px)] items-start left-1/2 px-[var(--space\/16,16px)] py-[var(--space\/20,20px)] top-[258px] w-[375px]" data-node-id="1015:45690">
        <div className="content-stretch flex flex-col gap-[12px] items-start relative shrink-0 w-full" data-node-id="1015:45694" data-name="Address card">
          <div className="bg-[#f0f0f5] border border-[#f6dbff] border-solid content-stretch flex flex-col items-start overflow-clip relative rounded-[var(--radius\/16,16px)] shadow-[0px_0px_0px_2px_#fcf5fe] shrink-0 w-full" data-node-id="1015:45695" data-name="Address cards">
            <div className="bg-[#fcf0ff] content-stretch flex h-[45px] items-center justify-between pl-[8px] pr-[4px] py-[8px] relative shrink-0 w-full" data-node-id="1015:45696" data-name="Top unit">
              <div className="content-stretch flex flex-[1_0_0] items-center justify-between min-w-px relative" data-node-id="1015:45697" data-name="Address header">
                <div className="content-stretch flex gap-[8px] items-center relative shrink-0" data-node-id="1015:45698" data-name="Address info">
                  <div className="bg-[var(--neutral\/white,white)] border border-[rgba(246,219,255,0.1)] border-solid drop-shadow-[0px_12.889px_14.844px_rgba(0,0,0,0.02)] relative rounded-[8px] shrink-0 size-[29px]" data-node-id="1015:45699" data-name="Card icon">
                    <div className="-translate-x-1/2 -translate-y-1/2 absolute left-1/2 size-[20px] top-1/2" data-node-id="I1015:45699;4360:17234" data-name="Component 217">
                      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgComponent217} />
                    </div>
                  </div>
                  <div className="content-stretch flex items-center relative shrink-0" data-node-id="1015:45700" data-name="Card text">
                    <div className="flex h-[18.658px] items-center justify-center relative shrink-0 w-[122.095px]" data-node-id="I1015:45700;4360:17319">
                      <div className="flex-none rotate-[-0.31deg]">
                        <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Noontree:Medium')] justify-center leading-[0] not-italic overflow-hidden relative text-[color:var(--neutral\/black,#0e0e0e)] text-[length:var(--fontsize\/label3,14px)] text-ellipsis tracking-[var(--letterspacing\/label3,-0.14px)] whitespace-nowrap" style={{ fontFeatureSettings: '"case" 1' }}>
                          <p className="leading-[var(--lineheight\/label3,18px)] overflow-hidden text-[14px] text-ellipsis">Work</p>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="bg-white content-stretch flex items-center justify-center pb-[4px] pl-[7px] pr-[6px] pt-[3px] relative rounded-[6px] shrink-0 w-[37px]" data-node-id="1015:45701" data-name="Card distance">
                    <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Noontree:Bold')] justify-center leading-[0] not-italic relative shrink-0 text-[color:var(--🚧-text\/👀-secondary,rgba(2,6,12,0.6))] text-[length:var(--fontsize\/tiny,10px)] tracking-[var(--letterspacing\/tiny,0px)] whitespace-nowrap" data-node-id="I1015:45701;4364:17350">
                      <p className="leading-[var(--lineheight\/tiny,12px)]">24 m</p>
                    </div>
                  </div>
                </div>
                <div className="content-stretch flex items-center px-[var(--space\/8,8px)] relative shrink-0" data-node-id="1015:45702" data-name="Checkbox">
                  <div className="max-h-[20px] max-w-[20px] min-h-[20px] min-w-[20px] relative shrink-0 size-[20px]" data-node-id="1015:45703" data-name="M-Checkbox">
                    <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMCheckbox} />
                  </div>
                </div>
              </div>
            </div>
            <div className="bg-[var(--neutral\/white,white)] content-stretch flex flex-col items-start overflow-clip p-[12px] relative shrink-0 w-full" data-node-id="1015:45704" data-name="Bottom unit">
              <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45704;4368:17454">
                <div className="content-stretch flex flex-col items-center relative shrink-0 w-full" data-node-id="I1015:45704;4368:17455">
                  <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45704;4368:17456">
                    <div className="content-stretch flex flex-col gap-[8px] items-start relative shrink-0 w-full" data-node-id="I1015:45704;4368:17457">
                      <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] min-w-full not-italic overflow-hidden relative shrink-0 text-[13px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] w-[min-content]" data-node-id="I1015:45704;4368:17458">
                        <p className="leading-[17px]">Burj Khalifa, 1 Sheikh Mohammed bin Rashid Blvd, Downtown Dubai</p>
                      </div>
                      <div className="h-0 relative shrink-0 w-full" data-node-id="I1015:45704;4368:17459">
                        <div className="absolute inset-[-1px_0_0_0]">
                          <img alt="" className="block max-w-none size-full" src={imgLine199} />
                        </div>
                      </div>
                      <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45704;4368:17460">
                        <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45704;4368:17461">
                          <div className="content-stretch flex gap-[4px] items-center relative shrink-0" data-node-id="I1015:45704;4368:17462">
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45704;4368:17463" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">Ahmed Ali,</p>
                            </div>
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45704;4368:17464" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">+971-50 789 3456</p>
                            </div>
                            <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45704;4368:17465">
                              <div className="relative shrink-0 size-[14px]" data-node-id="I1015:45704;4368:17466">
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
          <div className="bg-[var(--blue-gray\/100,#f9f9fb)] border border-[var(--blue-gray\/300,#eaecf0)] border-solid content-stretch flex flex-col items-start overflow-clip relative rounded-[var(--radius\/16,16px)] shrink-0 w-full" data-node-id="1015:45705" data-name="Address cards">
            <div className="content-stretch flex h-[45px] items-center justify-between pl-[8px] pr-[4px] py-[8px] relative shrink-0 w-full" data-node-id="1015:45706" data-name="Top unit">
              <div className="content-stretch flex flex-[1_0_0] items-center justify-between min-w-px relative" data-node-id="1015:45707" data-name="Address header">
                <div className="content-stretch flex gap-[8px] items-center relative shrink-0" data-node-id="1015:45708" data-name="Address info">
                  <div className="bg-[var(--neutral\/white,white)] border border-[var(--blue-gray\/200,#f2f3f7)] border-solid drop-shadow-[0px_12.889px_14.844px_rgba(0,0,0,0.02)] relative rounded-[8px] shrink-0 size-[29px]" data-node-id="1015:45709" data-name="Card icon">
                    <div className="-translate-x-1/2 -translate-y-1/2 absolute left-1/2 size-[20px] top-1/2" data-node-id="I1015:45709;4360:17234" data-name="Component 217">
                      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgComponent218} />
                    </div>
                  </div>
                  <CardText className="content-stretch flex items-center justify-center relative shrink-0 w-[122.095px]" />
                  <div className="bg-white content-stretch flex items-center justify-center pb-[4px] pl-[7px] pr-[6px] pt-[3px] relative rounded-[6px] shrink-0 w-[37px]" data-node-id="1015:45711" data-name="Card distance">
                    <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Noontree:Bold')] justify-center leading-[0] not-italic relative shrink-0 text-[color:var(--blue-gray\/700,#475067)] text-[length:var(--fontsize\/tiny,10px)] tracking-[var(--letterspacing\/tiny,0px)] whitespace-nowrap" data-node-id="I1015:45711;4364:17350">
                      <p className="leading-[var(--lineheight\/tiny,12px)]">24 m</p>
                    </div>
                  </div>
                </div>
                <div className="content-stretch flex items-center px-[var(--space\/8,8px)] relative shrink-0" data-node-id="1015:45712" data-name="Checkbox">
                  <MCheckbox className="max-h-[24px] max-w-[24px] min-h-[24px] min-w-[24px] relative shrink-0 size-[24px]" />
                </div>
              </div>
            </div>
            <div className="bg-[var(--neutral\/white,white)] content-stretch flex flex-col items-start overflow-clip p-[12px] relative shrink-0 w-full" data-node-id="1015:45714" data-name="Bottom unit">
              <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45714;4368:17454">
                <div className="content-stretch flex flex-col items-center relative shrink-0 w-full" data-node-id="I1015:45714;4368:17455">
                  <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45714;4368:17456">
                    <div className="content-stretch flex flex-col gap-[8px] items-start relative shrink-0 w-full" data-node-id="I1015:45714;4368:17457">
                      <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] min-w-full not-italic overflow-hidden relative shrink-0 text-[13px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] w-[min-content]" data-node-id="I1015:45714;4368:17458">
                        <p className="leading-[17px]">Burj Khalifa, 1 Sheikh Mohammed bin Rashid Blvd, Downtown Dubai</p>
                      </div>
                      <div className="h-0 relative shrink-0 w-full" data-node-id="I1015:45714;4368:17459">
                        <div className="absolute inset-[-1px_0_0_0]">
                          <img alt="" className="block max-w-none size-full" src={imgLine199} />
                        </div>
                      </div>
                      <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45714;4368:17460">
                        <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45714;4368:17461">
                          <div className="content-stretch flex gap-[4px] items-center relative shrink-0" data-node-id="I1015:45714;4368:17462">
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45714;4368:17463" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">Ahmed Ali,</p>
                            </div>
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45714;4368:17464" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">+971-50 789 3456</p>
                            </div>
                            <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45714;4368:17465">
                              <div className="relative shrink-0 size-[14px]" data-node-id="I1015:45714;4368:17466">
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
          <div className="bg-[var(--blue-gray\/100,#f9f9fb)] border border-[var(--blue-gray\/300,#eaecf0)] border-solid content-stretch flex flex-col items-start overflow-clip relative rounded-[var(--radius\/16,16px)] shrink-0 w-full" data-node-id="1015:45715" data-name="Address cards">
            <div className="content-stretch flex h-[45px] items-center justify-between pl-[8px] pr-[4px] py-[8px] relative shrink-0 w-full" data-node-id="1015:45716" data-name="Top unit">
              <div className="content-stretch flex flex-[1_0_0] items-center justify-between min-w-px relative" data-node-id="1015:45717" data-name="Address header">
                <div className="content-stretch flex gap-[8px] items-center relative shrink-0" data-node-id="1015:45718" data-name="Address info">
                  <div className="bg-[var(--neutral\/white,white)] border border-[var(--blue-gray\/200,#f2f3f7)] border-solid drop-shadow-[0px_12.889px_14.844px_rgba(0,0,0,0.02)] relative rounded-[8px] shrink-0 size-[29px]" data-node-id="1015:45719" data-name="Card icon">
                    <div className="-translate-x-1/2 -translate-y-1/2 absolute left-1/2 size-[20px] top-1/2" data-node-id="I1015:45719;4360:17234" data-name="Component 217">
                      <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgComponent218} />
                    </div>
                  </div>
                  <CardText className="content-stretch flex items-center justify-center relative shrink-0 w-[122.095px]" />
                  <div className="bg-white content-stretch flex items-center justify-center pb-[4px] pl-[7px] pr-[6px] pt-[3px] relative rounded-[6px] shrink-0 w-[37px]" data-node-id="1015:45721" data-name="Card distance">
                    <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Noontree:Bold')] justify-center leading-[0] not-italic relative shrink-0 text-[color:var(--blue-gray\/700,#475067)] text-[length:var(--fontsize\/tiny,10px)] tracking-[var(--letterspacing\/tiny,0px)] whitespace-nowrap" data-node-id="I1015:45721;4364:17350">
                      <p className="leading-[var(--lineheight\/tiny,12px)]">24 m</p>
                    </div>
                  </div>
                </div>
                <div className="content-stretch flex items-center px-[var(--space\/8,8px)] relative shrink-0" data-node-id="1015:45722" data-name="Checkbox">
                  <MCheckbox className="max-h-[24px] max-w-[24px] min-h-[24px] min-w-[24px] relative shrink-0 size-[24px]" />
                </div>
              </div>
            </div>
            <div className="bg-[var(--neutral\/white,white)] content-stretch flex flex-col items-start overflow-clip p-[12px] relative shrink-0 w-full" data-node-id="1015:45724" data-name="Bottom unit">
              <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45724;4368:17454">
                <div className="content-stretch flex flex-col items-center relative shrink-0 w-full" data-node-id="I1015:45724;4368:17455">
                  <div className="content-stretch flex flex-col items-start relative shrink-0 w-full" data-node-id="I1015:45724;4368:17456">
                    <div className="content-stretch flex flex-col gap-[8px] items-start relative shrink-0 w-full" data-node-id="I1015:45724;4368:17457">
                      <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] min-w-full not-italic overflow-hidden relative shrink-0 text-[13px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] w-[min-content]" data-node-id="I1015:45724;4368:17458">
                        <p className="leading-[17px]">Burj Khalifa, 1 Sheikh Mohammed bin Rashid Blvd, Downtown Dubai</p>
                      </div>
                      <div className="h-0 relative shrink-0 w-full" data-node-id="I1015:45724;4368:17459">
                        <div className="absolute inset-[-1px_0_0_0]">
                          <img alt="" className="block max-w-none size-full" src={imgLine199} />
                        </div>
                      </div>
                      <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45724;4368:17460">
                        <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45724;4368:17461">
                          <div className="content-stretch flex gap-[4px] items-center relative shrink-0" data-node-id="I1015:45724;4368:17462">
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45724;4368:17463" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">Ahmed Ali,</p>
                            </div>
                            <div className="[word-break:break-word] flex flex-col font-[family-name:var(--fontfamily\/primary,'Figtree:Regular')] justify-center leading-[0] not-italic overflow-hidden relative shrink-0 text-[12px] text-[color:var(--blue-gray\/900,#1d2539)] text-ellipsis tracking-[-0.05px] whitespace-nowrap" data-node-id="I1015:45724;4368:17464" style={{ fontFeatureSettings: '"case" 1' }}>
                              <p className="leading-[17px] overflow-hidden text-ellipsis">+971-50 789 3456</p>
                            </div>
                            <div className="content-stretch flex items-center relative shrink-0" data-node-id="I1015:45724;4368:17465">
                              <div className="relative shrink-0 size-[14px]" data-node-id="I1015:45724;4368:17466">
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
        <div className="absolute flex h-[20px] items-center justify-center left-[182px] top-[47px] w-0" data-node-id="1015:45725">
          <div className="flex-none rotate-90">
            <div className="h-0 relative w-[20px]">
              <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgLine200} />
            </div>
          </div>
        </div>
      </div>
      <div className="absolute bottom-0 content-stretch drop-shadow-[0px_-167px_23.5px_rgba(224,224,224,0),0px_-107px_21.5px_rgba(224,224,224,0.01),0px_-60px_18px_rgba(224,224,224,0.05),0px_-27px_13.5px_rgba(224,224,224,0.09),0px_-7px_7.5px_rgba(224,224,224,0.1)] flex flex-col items-center justify-center left-0 overflow-clip rounded-tl-[var(--radius\/20,20px)] rounded-tr-[var(--radius\/20,20px)] w-[375px]" data-node-id="1015:45726">
        <div className="bg-[var(--colour\/surface\/primary,white)] content-stretch flex gap-[var(--space\/12,12px)] items-center p-[var(--space\/12,12px)] relative shrink-0 w-[375px]" data-node-id="1015:45727" data-name="M-RowActionBar">
          <div className="bg-[var(--colour\/surface\/primary,white)] border border-[var(--colour\/border\/primary,#eaecf0)] border-solid content-stretch flex flex-[1_0_0] gap-[var(--space\/8,8px)] items-center justify-center max-h-[52px] min-h-[52px] min-w-px px-[var(--space\/20,20px)] py-[var(--space\/14,14px)] relative rounded-[var(--radius\/12,12px)]" data-node-id="I1015:45727;1735:95" data-name="M-SecondaryNeutralButton">
            <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/action\/a16\/line-height,24px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/primary,#1d2539)] text-[length:var(--font\/action\/a16\/size,16px)] tracking-[var(--font\/action\/a16\/letter-spacing,0px)] whitespace-nowrap" data-node-id="I1015:45727;1735:95;944:12597">
              Back
            </p>
          </div>
          <div className="border border-[#e0e0e0] border-solid content-stretch flex flex-[1_0_0] gap-[var(--space\/8,8px)] items-center justify-center max-h-[52px] min-h-[52px] min-w-px overflow-clip px-[var(--gap\/14,14px)] py-[var(--space\/14,14px)] relative rounded-[var(--radius\/12,12px)]" data-node-id="I1015:45727;1735:101" data-name="M-NeutralButton">
            <div aria-hidden className="absolute bg-gradient-to-b from-[#2a2c2e] inset-0 pointer-events-none rounded-[var(--radius\/12,12px)] to-[#101112]" />
            <p className="[word-break:break-word] font-[family-name:var(--base\/font\/family\/primary,'Noontree:SemiBold')] font-[var(--base\/font\/weight\/semibold,normal)] leading-[var(--font\/action\/a16\/line-height,24px)] relative shrink-0 text-[color:var(--colour\/text-n-icon\/on-surface-bold,white)] text-[length:var(--font\/action\/a16\/size,16px)] tracking-[var(--font\/action\/a16\/letter-spacing,0px)] whitespace-nowrap" data-node-id="I1015:45727;1735:101;752:90">
              Continue
            </p>
            <div className="absolute inset-0 pointer-events-none rounded-[inherit] shadow-[inset_0px_-14.667px_14.667px_0px_#0c0d0e,inset_0px_14.667px_14.667px_0px_#2e2f32]" />
          </div>
        </div>
        <div className="bg-[var(--colour\/surface\/primary,white)] h-[24px] relative shrink-0 w-full" data-node-id="1015:45728" data-name="Home bar">
          <div className="absolute bg-[#262a33] inset-[41.67%_33.33%_37.5%_33.6%] rounded-[8px]" data-node-id="1015:45729" data-name="Home bar" />
        </div>
      </div>
      <div className="-translate-x-1/2 -translate-y-1/2 absolute h-[812px] left-1/2 overflow-clip top-[calc(50%-0.43px)] w-[375px]" data-node-id="1015:45730" data-name="Overlay">
        <div className="absolute contents left-[-347.95px] top-[95px]" data-node-id="1015:45731">
          <div className="-translate-x-1/2 absolute contents left-1/2 top-[95px]" data-node-id="1015:45732">
            <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[rgba(164,119,255,0)] h-[647.833px] left-1/2 to-[#6724ee] to-[94.052%] top-[95px] via-[47.026%] via-[rgba(133,77,246,0.5)] w-[399.843px]" data-node-id="1015:45733" />
            <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[rgba(164,119,255,0)] h-[647.833px] left-1/2 to-[#6724ee] to-[94.052%] top-[95px] via-[47.026%] via-[rgba(133,77,246,0.5)] w-[399.843px]" data-node-id="1015:45734" />
            <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[rgba(164,119,255,0)] h-[647.833px] left-1/2 to-[#6724ee] to-[94.052%] top-[95px] via-[47.026%] via-[rgba(133,77,246,0.5)] w-[399.843px]" data-node-id="1015:45735" />
            <div className="-translate-x-1/2 absolute bg-gradient-to-b from-[rgba(164,119,255,0)] h-[693.707px] left-1/2 to-[#6724ee] to-[94.052%] top-[118.29px] via-[47.026%] via-[rgba(133,77,246,0.5)] w-[399.843px]" data-node-id="1015:45736" />
          </div>
          <div className="absolute flex h-[438.287px] items-center justify-center left-[-12.77px] top-[403.08px] w-[442.301px]" data-node-id="1015:45737">
            <div className="flex-none rotate-[13.84deg] skew-x-[-1.09deg]">
              <div className="h-[364.785px] relative w-[358.772px]">
                <div className="absolute inset-[-0.88%_-0.25%_-0.4%_-0.83%]">
                  <img alt="" className="block max-w-none size-full" src={imgVector20710} />
                </div>
              </div>
            </div>
          </div>
          <div className="-translate-x-1/2 absolute h-[124.112px] left-[calc(50%-5.33px)] top-[528.35px] w-[296.217px]" data-node-id="1015:45738" data-name="image 1583515817">
            <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515817} />
          </div>
          <div className="-translate-x-1/2 absolute blur-[42px] h-[124.112px] left-[calc(50%-2.33px)] opacity-70 top-[531.23px] w-[296.217px]" data-node-id="1015:45739" data-name="image 1583515818">
            <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515818} />
          </div>
          <div className="-translate-x-1/2 absolute h-[124.112px] left-[calc(50%-10.89px)] top-[523.43px] w-[296.217px]" data-node-id="1015:45740" data-name="image 1583515815">
            <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage1583515815} />
          </div>
          <div className="absolute h-[58.949px] left-[283.33px] top-[506.38px] w-[58.088px]" data-node-id="1015:45741">
            <div className="absolute inset-[-5.61%_-5.69%]">
              <img alt="" className="block max-w-none size-full" src={imgGroup2147241962} />
            </div>
          </div>
          <div className="absolute h-[129.361px] left-[-347.95px] top-[661.67px] w-[767.467px]" data-node-id="1015:45745" data-name="Union">
            <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgUnion} />
          </div>
          <div className="absolute h-[34.65px] left-[275.79px] top-[666.69px] w-[128.232px]" data-node-id="1015:45757">
            <div className="absolute inset-[-106.25%_-28.71%_-106.25%_-25.64%]">
              <img alt="" className="block max-w-none size-full" src={imgVector20714} />
            </div>
          </div>
          <div className="absolute flex items-center justify-center left-[227.78px] size-[128.73px] top-[563.87px]" data-node-id="1015:45758">
            <div className="flex-none rotate-[-35.82deg]">
              <div className="relative size-[92.208px]" data-name="image 271146229">
                <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage271146229} />
              </div>
            </div>
          </div>
          <div className="absolute h-[23.636px] left-[304.4px] top-[590.18px] w-[25.741px]" data-node-id="1015:45759" data-name="image 271146307">
            <div className="absolute inset-0 overflow-hidden pointer-events-none">
              <img alt="" className="absolute h-[186.85%] left-[-35.2%] max-w-none top-[-74.28%] w-[171.57%]" src={imgImage271146307} />
            </div>
          </div>
          <div className="absolute flex h-[64.571px] items-center justify-center left-[286.19px] top-[474.74px] w-[62.772px]" data-node-id="1015:45760">
            <div className="flex-none rotate-[-28.12deg] skew-x-[1.92deg]">
              <div className="h-[51.865px] relative w-[41.737px]">
                <div className="absolute inset-[-4.84%_-6.38%_-5.81%_-7.23%]">
                  <img alt="" className="block max-w-none size-full" src={imgGroup2147241956} />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="absolute flex h-[429.04px] items-center justify-center left-[-263.03px] top-[351.54px] w-[413.27px]" data-node-id="1015:45763">
          <div className="flex-none rotate-[171.2deg]">
            <div className="h-[378.492px] relative w-[359.612px]">
              <div className="absolute inset-[-0.84%_-0.26%_-0.38%_-0.83%]">
                <img alt="" className="block max-w-none size-full" src={imgVector20711} />
              </div>
            </div>
          </div>
        </div>
        <div className="absolute flex h-[40.045px] items-center justify-center left-[125.12px] top-[476.46px] w-[40.308px]" data-node-id="1015:45764">
          <div className="flex-none rotate-[28.35deg]">
            <div className="h-[29.328px] relative w-[29.977px]" data-name="image 271146178">
              <div className="absolute inset-0 overflow-hidden pointer-events-none">
                <img alt="" className="absolute h-[784.15%] left-[-140.24%] max-w-none top-[-171.35%] w-[511.45%]" src={imgImage271146178} />
              </div>
            </div>
          </div>
        </div>
        <div className="absolute flex h-[171.149px] items-center justify-center left-[-19.72px] top-[615.92px] w-[172.377px]" data-node-id="1015:45765">
          <div className="flex-none rotate-[140.45deg]">
            <div className="blur-[12px] h-[117.437px] relative w-[126.575px]" data-name="image 271146308">
              <img alt="" className="absolute inset-0 max-w-none object-cover pointer-events-none size-full" src={imgImage271146308} />
            </div>
          </div>
        </div>
        <div className="absolute flex h-[45.56px] items-center justify-center left-[180.21px] top-[524.87px] w-[131.913px]" data-node-id="1015:45766">
          <div className="flex-none rotate-[-2.15deg]">
            <div className="h-[40.682px] relative w-[130.475px]">
              <div className="absolute inset-[-24.53%_-7.65%]">
                <img alt="" className="block max-w-none size-full" src={imgVector20717} />
              </div>
            </div>
          </div>
        </div>
        <div className="absolute flex h-[45.56px] items-center justify-center left-[180.21px] top-[524.87px] w-[131.913px]" data-node-id="1015:45767">
          <div className="flex-none rotate-[-2.15deg]">
            <div className="h-[40.682px] relative w-[130.475px]">
              <div className="absolute inset-[-24.53%_-7.65%]">
                <img alt="" className="block max-w-none size-full" src={imgVector20717} />
              </div>
            </div>
          </div>
        </div>
        <div className="absolute flex h-[45.56px] items-center justify-center left-[180.21px] top-[524.87px] w-[131.913px]" data-node-id="1015:45768">
          <div className="flex-none rotate-[-2.15deg]">
            <div className="h-[40.682px] relative w-[130.475px]">
              <div className="absolute inset-[-24.53%_-7.65%]">
                <img alt="" className="block max-w-none size-full" src={imgVector20717} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
