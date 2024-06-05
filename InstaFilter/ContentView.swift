//
//  ContentView.swift
//  InstaFilter
//
//  Created by Igor Florentino on 04/06/24.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit

struct ContentView: View {
	@AppStorage("filterCount") var filterCount = 0
	@Environment(\.requestReview) var requestReview
	
	@State private var processedImage: Image?
	@State private var filterItensity = 0.5
	@State private var filterRadius = 0.5
	@State private var filterScale = 0.5
	@State private var selectedItem: PhotosPickerItem?
	@State private var currentFilter: CIFilter = CIFilter.sepiaTone()
	@State private var showingFilters = false
	private var inputKeys: [String] { currentFilter.inputKeys }
	
	let context = CIContext()
	
	var body: some View {
		NavigationStack{
			VStack {
				
				Spacer()
				
				PhotosPicker(selection: $selectedItem){
					if let processedImage {
						processedImage
							.resizable()
							.scaledToFit()
					} else {
						ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
					}
				}
				.onChange(of: selectedItem, loadImage)
				
				Spacer()
				
				if inputKeys.contains(kCIInputIntensityKey) {
					HStack{
						Text("Itensity")
						Slider(value: $filterItensity)
							.onChange(of: filterItensity, applyProcessing)
					}
					.padding(.bottom)
					.disabled(processedImage == nil)
				}
				
				if inputKeys.contains(kCIInputRadiusKey) {
					HStack{
						Text("Radius")
						Slider(value: $filterRadius, in:0...200)
							.onChange(of: filterRadius, applyProcessing)
					}
					.padding(.bottom)
					.disabled(processedImage == nil)
				}
				
				if inputKeys.contains(kCIInputScaleKey) {
					HStack{
						Text("Scale")
						Slider(value: $filterScale, in:0...10)
							.onChange(of: filterScale, applyProcessing)
					}
					.padding(.bottom)
					.disabled(processedImage == nil)
				}
				
				HStack{
					Button("Change Filter", action: changeFilter)
					
					Spacer()
					
					if let processedImage {
						ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
					}
				}
				.disabled(processedImage == nil)
				
			}
			.padding([.horizontal, .bottom])
			.navigationTitle("Instafilter")
			.confirmationDialog("Select a filter", isPresented: $showingFilters) {
				Button("Crystallize"){ setFilter(.crystallize())}
				Button("Edges"){ setFilter(.edges())}
				Button("Gaussian Blur"){ setFilter(.gaussianBlur())}
				Button("Pixellate"){ setFilter(.pixellate())}
				Button("Sepia Tone"){ setFilter(.sepiaTone())}
				Button("Unsharp Mask"){ setFilter(.unsharpMask())}
				Button("Vignette"){ setFilter(.vignette())}
				Button("Bump Distortion"){ setFilter(.bumpDistortion())}
				Button("Comic Effect"){ setFilter(.comicEffect())}
				Button("Kaleidoscope"){ setFilter(.kaleidoscope())}
				Button("Cancel", role: .cancel){ }
			}
		}
	}
	
	func changeFilter(){
		showingFilters = true
	}
	
	func loadImage(){
		Task{
			guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
			guard let inputImage = UIImage(data: imageData) else { return }
			
			let beginImage = CIImage(image: inputImage)
			currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
			applyProcessing()
		}
	}
	
	func applyProcessing(){
		if inputKeys.contains(kCIInputIntensityKey) {
			currentFilter.setValue(filterItensity, forKey: kCIInputIntensityKey)
		}
		if inputKeys.contains(kCIInputRadiusKey) {
			currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey)
		}
		if inputKeys.contains(kCIInputScaleKey) {
			currentFilter.setValue(filterScale, forKey: kCIInputScaleKey)
		}
		
		guard let outputImage = currentFilter.outputImage else { return }
		guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
		
		let uiImage = UIImage(cgImage: cgImage)
		processedImage = Image(uiImage: uiImage)
	}
	
	@MainActor func setFilter(_ filter: CIFilter){
		currentFilter = filter
		loadImage()
		
		filterCount += 1
		
		if filterCount >= 20 {
			requestReview()
		}
	}
}

#Preview {
    ContentView()
}
