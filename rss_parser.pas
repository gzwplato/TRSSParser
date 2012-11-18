unit rss_parser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,Variants, DateUtils,HTTPDefs, XMLRead,XMLWrite,Dom, rss_types,rss_utils;

type

{ TRSSParser }

 TRSSParser = class(TRSSStorage)
  private
    function FetchNextToken(var s: string; space: string = ' '): string;
    function MonthToInt(MonthStr: string): Integer;
    function ParseRSSDate(DateStr: string): TDateTime;
    function GetNodeValue(aNode:TDOMNode;aTag: string):string;
    function DateTimeToGMT(const ADateTime: TDateTime): string;
  public
    procedure ParseRSSChannel(const RSSData: string);
    procedure SaveRSSChannels(const aPath: string);
    end;

implementation

{ TRSSParser }

function TRSSParser.FetchNextToken(var s: string; space: string): string;
var
  SpacePos: Integer;
begin
  SpacePos := Pos(space, s);
  if SpacePos = 0 then
  begin
    Result := s;
    s := '';
  end
  else
  begin
    Result := System.Copy(s, 1, SpacePos - 1);
    System.Delete(s, 1, SpacePos);
  end;
end;

function TRSSParser.MonthToInt(MonthStr: string): Integer;
const
  Months: array [1..12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
    'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
var
  M: Integer;
begin
  for M := 1 to 12 do
    if Months[M] = MonthStr then
      Exit(M);
  raise Exception.CreateFmt('Unknown month: %s', [MonthStr]);
end;

function TRSSParser.ParseRSSDate(DateStr: string): TDateTime;
var
  df: TFormatSettings;
  s: string;
  Day, Month, Year, Hour, Minute, Second: Integer;
begin
  s := DateStr;
  // Parsing date in this format: Mon, 11 Nov 2012 16:45:00 +0000
  try
    FetchNextToken(s);                          // Ignore "Mon, "
    Day := StrToInt(FetchNextToken(s));         // "11"
    Month := MonthToInt(FetchNextToken(s));     // "Nov"
    Year := StrToInt(FetchNextToken(s));        // "2012"
    Hour := StrToInt(FetchNextToken(s, ':'));   // "16"
    Minute := StrToInt(FetchNextToken(s, ':')); // "45"
    Second := StrToInt(FetchNextToken(s));      // "00"
    Result := EncodeDate(Year, Month, Day) + EncodeTime(Hour, Minute, Second, 0);
  except
    on E: Exception do
      raise Exception.CreateFmt('Can''t parse date "%s": %s',
        [DateStr, E.Message]);
  end;
end;

function TRSSParser.GetNodeValue(aNode: TDOMNode; aTag: string): string;
  var
  oNode: TDOMNode;
begin
  Result := '';
  if Assigned(ANode) then
  begin
    oNode := ANode.FindNode(DOMString(ATag));
    if Assigned(oNode) then
    begin
        Result := Convert(oNode.TextContent);
    end;
  end;
end;

function TRSSParser.DateTimeToGMT(const ADateTime: TDateTime): string;
var
  VYear, VMonth, VDay, VHour, VMinute, VSecond, M: Word;
begin
  DecodeDate(ADateTime, VYear, VMonth, VDay);
  DecodeTime(ADateTime, VHour, VMinute, VSecond, M);
  Result := Format('%s, %.2d %s %d %.2d:%.2d:%.2d GMT',
    [HTTPDays[DayOfWeek(ADateTime)], VDay, HTTPMonths[VMonth], VYear, VHour,
    VMinute, VSecond]);
end;

procedure TRSSParser.ParseRSSChannel(const RSSData: string);
      procedure DoLoadItems(aParentNode: TDOMNode; aRSSChannel: TRSSChannel);
           var
             oRSSItem: TRSSItem;
             oNode: TDOMNode;
             RSSItems: TDOMNodeList;
             i: integer;
           begin
              RssItems:=aParentNode.GetChildNodes;
              for i:=0 to RSSItems.Count-1 do
               begin
               oNode:=RssItems[i];
               if CompareStr(oNode.NodeName,'item') = 0 then
               begin
               oRSSItem:=aRSSChannel.RSSList.AddItem;
               oRSSItem.Title := GetNodeValue(oNode,'title');
               oRSSItem.Link  := GetNodeValue(oNode,'link');
               oRSSItem.Description   := GetNodeValue(oNode,'description');
               oRSSItem.PubDate   := DateToStr(ParseRssDate(GetNodeValue(oNode,'pubDate')));
               oRSSItem.Author := GetNodeValue(oNode,'author');
               oRSSItem.Category := GetNodeValue(oNode,'category');
               oRssItem.Guid := GetNodeValue(oNode,'guid');
               oRSSItem.Comments:= GetNodeValue(oNode,'comments');
               end;
            end;
           end;

           procedure DoLoadChannels(aNode: TDOMNode);
           var
             oNode: TDOMNode;
             oRSSChannel: TRSSChannel;
           begin
               oRSSChannel:=AddItem;
               oNode:=aNode;
               oRSSChannel.Title:=GetNodeValue(oNode,'title');
                oRSSChannel.Link:=GetNodeValue(oNode,'link');
               oRSSChannel.Description:=GetNodeValue(oNode,'description');
               oRSSChannel.Category:=GetNodeValue(oNode,'category');
               oRSSChannel.Copyright:=GetNodeValue(oNode,'copyright');
               oRSSChannel.LastBuildDate:=GetNodeValue(oNode,'lastBuildDate');
               oRSSChannel.Language:=GetNodeValue(oNode,'language'); ;
               DoLoadItems(oNode, oRSSChannel);
           end;
         var
           oXmlDocument: TXmlDocument;
            RSS: TStringStream;
             s,RssStr: string;
         begin
           oXMLDocument:=TXMLDocument.Create;
           RssStr:=RSSData;
           if not (pos('windows-1251',RssStr )=0) then
             begin
               s:=ReplaceStr(RssStr,'windows-1251','UTF-8');
               RssStr:=AnsiToUtf8(s);
             end;
           RSS:=TStringStream.Create(RssStr);
           RSS.Position:=0;
           ReadXMLFile(oXmlDocument,RSS);
           DoLoadChannels (oXmlDocument.DocumentElement.FindNode('channel'));
           FreeAndNil(oXmlDocument);
         end;

procedure TRSSParser.SaveRSSChannels(const aPath: string);
  procedure SaveChannel(Channel: TRSSChannel;aFilePath: string);
   var
     oXmlDocument: TXmlDocument;
      i: integer;
      vRoot,vFeed,vItem: TDomNode;
    begin
      oXmlDocument:=TXMLDocument.Create;
      vRoot:=oXmlDocument.CreateElement('rss');
      TDOMElement(vRoot).SetAttribute('version', '2.0');
      vFeed:=oXmlDocument.CreateElement('channel');



      end;

begin

end;



end.

