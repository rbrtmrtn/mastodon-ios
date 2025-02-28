//
//  ComposeContentView.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import os.log
import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonLocalization
import Stripes
import Kingfisher

public struct ComposeContentView: View {
    
    static let logger = Logger(subsystem: "ComposeContentView", category: "View")
    var logger: Logger { ComposeContentView.logger }
    
    static let contentViewCoordinateSpace = "ComposeContentView.Content"
    static var margin: CGFloat = 16
    
    @ObservedObject var viewModel: ComposeContentViewModel
    

    public var body: some View {
        VStack(spacing: .zero) {
            Group {
                // content warning
                if viewModel.isContentWarningActive {
                    MetaTextViewRepresentable(
                        string: $viewModel.contentWarning,
                        width: viewModel.viewLayoutFrame.layoutFrame.width - ComposeContentView.margin * 2,
                        configurationHandler: { metaText in
                            viewModel.contentWarningMetaText = metaText
                            metaText.textView.attributedPlaceholder = {
                                var attributes = metaText.textAttributes
                                attributes[.foregroundColor] = UIColor.secondaryLabel
                                return NSAttributedString(
                                    string: L10n.Scene.Compose.contentInputPlaceholder,
                                    attributes: attributes
                                )
                            }()
                            metaText.textView.returnKeyType = .next
                            metaText.textView.tag = ComposeContentViewModel.MetaTextViewKind.contentWarning.rawValue
                            metaText.textView.delegate = viewModel
                            metaText.delegate = viewModel
                        }
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, ComposeContentView.margin)
                    .background(
                        Color(UIColor.systemBackground)
                            .overlay(
                                HStack {
                                    Stripes(config: StripesConfig(
                                        background: Color.yellow,
                                        foreground: Color.black,
                                        degrees: 45,
                                        barWidth: 2.5,
                                        barSpacing: 3.5
                                    ))
                                    .frame(width: ComposeContentView.margin * 0.5)
                                    .frame(maxHeight: .infinity)
                                    .id(UUID())
                                    Spacer()
                                    Stripes(config: StripesConfig(
                                        background: Color.yellow,
                                        foreground: Color.black,
                                        degrees: 45,
                                        barWidth: 2.5,
                                        barSpacing: 3.5
                                    ))
                                    .frame(width: ComposeContentView.margin * 0.5)
                                    .frame(maxHeight: .infinity)
                                    .scaleEffect(x: -1, y: 1, anchor: .center)
                                    .id(UUID())
                                }
                            )
                    )
                } // end if viewModel.isContentWarningActive
                // author
                authorView
                    .padding(.top, 14)
                    .padding(.horizontal, ComposeContentView.margin)
                // content editor
                MetaTextViewRepresentable(
                    string: $viewModel.content,
                    width: viewModel.viewLayoutFrame.layoutFrame.width - ComposeContentView.margin * 2,
                    configurationHandler: { metaText in
                        viewModel.contentMetaText = metaText
                        metaText.textView.attributedPlaceholder = {
                            var attributes = metaText.textAttributes
                            attributes[.foregroundColor] = UIColor.secondaryLabel
                            return NSAttributedString(
                                string: L10n.Scene.Compose.contentInputPlaceholder,
                                attributes: attributes
                            )
                        }()
                        metaText.textView.keyboardType = .twitter
                        metaText.textView.tag = ComposeContentViewModel.MetaTextViewKind.content.rawValue
                        metaText.textView.delegate = viewModel
                        metaText.delegate = viewModel
                        metaText.textView.becomeFirstResponder()
                    }
                )
                .frame(minHeight: 100)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ComposeContentView.margin)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: ViewFramePreferenceKey.self, value: proxy.frame(in: .named(ComposeContentView.contentViewCoordinateSpace)))
                    }
                    .onPreferenceChange(ViewFramePreferenceKey.self) { frame in
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): content textView frame: \(frame.debugDescription)")
                        let rect = frame.standardized
                        viewModel.contentTextViewFrame = CGRect(
                            origin: frame.origin,
                            size: CGSize(width: floor(rect.width), height: floor(rect.height))
                        )
                    }
                )
                // poll
                pollView
                    .padding(.horizontal, ComposeContentView.margin)
                // media
                mediaView
                    .padding(.horizontal, ComposeContentView.margin)
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ViewFramePreferenceKey.self, value: proxy.frame(in: .local))
                }
                .onPreferenceChange(ViewFramePreferenceKey.self) { frame in
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): content frame: \(frame.debugDescription)")
                    let rect = frame.standardized
                    viewModel.contentCellFrame = CGRect(
                        origin: frame.origin,
                        size: CGSize(width: floor(rect.width), height: floor(rect.height))
                    )
                }
            )
            Spacer()
        }   // end VStack
        .coordinateSpace(name: ComposeContentView.contentViewCoordinateSpace)
    }   // end body
}

extension ComposeContentView {
    var authorView: some View {
        HStack(spacing: 8) {
            AnimatedImage(imageURL: viewModel.avatarURL)
                .frame(width: 46, height: 46)
                .background(Color(UIColor.systemFill))
                .cornerRadius(12)
            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                MetaLabelRepresentable(
                    textStyle: .statusName,
                    metaContent: viewModel.name
                )
                Text(viewModel.username)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                Spacer()
            }
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Scene.Compose.Accessibility.postingAs([viewModel.name.string, viewModel.username].joined(separator: ", ")))
    }
}

extension ComposeContentView {
    // MARK: - poll
    var pollView: some View {
        VStack {
            if viewModel.isPollActive {
                // poll option TextField
                ReorderableForEach(
                    items: $viewModel.pollOptions
                ) { $pollOption in
                    let _index = viewModel.pollOptions.firstIndex(of: pollOption)
                    PollOptionRow(
                        viewModel: pollOption,
                        index: _index,
                        deleteBackwardResponseTextFieldRelayDelegate: viewModel
                    ) { textField in
                        viewModel.customEmojiPickerInputViewModel.configure(textInput: textField)
                    }
                }
                if viewModel.maxPollOptionLimit != viewModel.pollOptions.count {
                    PollAddOptionRow()
                        .onTapGesture {
                            viewModel.createNewPollOptionIfCould()
                        }
                }
                Menu {
                    Picker(selection: $viewModel.pollExpireConfigurationOption) {
                        ForEach(PollComposeItem.ExpireConfiguration.Option.allCases, id: \.self) { option in
                            Text(option.title)
                        }
                    } label: {
                        Text(L10n.Scene.Compose.Poll.durationTime(viewModel.pollExpireConfigurationOption.title))
                    }
                } label: {
                    HStack {
                        Text(L10n.Scene.Compose.Poll.durationTime(viewModel.pollExpireConfigurationOption.title))
                            .foregroundColor(Color(UIColor.label.withAlphaComponent(0.8)))  // Gray/800
                            .font(Font(UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }   // end VStack
    }
    
    // MARK: - media
    var mediaView: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.attachmentViewModels, id: \.self) { attachmentViewModel in
                AttachmentView(viewModel: attachmentViewModel)
                    .clipShape(Rectangle())
                    .badgeView(
                        Button {
                            viewModel.attachmentViewModels.removeAll(where: { $0 === attachmentViewModel })
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    )
            }   // end ForEach
        }   // end VStack
    }
}

//private struct ScrollOffsetPreferenceKey: PreferenceKey {
//    static var defaultValue: CGPoint = .zero
//
//    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
//}

private struct ViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { }
}

// MARK: - TypeIdentifiedItemProvider
extension PollComposeItem.Option: TypeIdentifiedItemProvider {
    public static var typeIdentifier: String {
        return Bundle(for: PollComposeItem.Option.self).bundleIdentifier! + String(describing: type(of: PollComposeItem.Option.self))
    }
}

// MARK: - NSItemProviderWriting
extension PollComposeItem.Option: NSItemProviderWriting {
    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        completionHandler(nil, nil)
        return nil
    }
    
    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [Self.typeIdentifier]
    }
}
